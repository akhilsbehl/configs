mod model;

use model::{
    filter_sessions, filter_snapshot, next_index, normalize_sessions, Navigation, Pane, PaneData,
    SearchMatch, SessionData, Snapshot, TargetId,
};
use std::collections::BTreeMap;
use std::time::Duration;
use zellij_tile::prelude::*;

#[derive(Clone, Copy)]
struct FloatingContext {
    tab_id: usize,
    was_visible: bool,
    pane: Option<(bool, u32)>,
}

#[derive(Clone, Copy, Default, Eq, PartialEq)]
enum Mode {
    #[default]
    PaneSwitcher,
    SessionManager,
}

#[derive(Default)]
struct State {
    snapshot: Snapshot,
    floating_visibility: BTreeMap<usize, bool>,
    tab_ids: BTreeMap<usize, usize>,
    switcher_tab_position: Option<usize>,
    origin_pane: Option<(bool, u32)>,
    floating_context: Option<FloatingContext>,
    mode: Mode,
    query: String,
    pane_query: String,
    session_query: Option<String>,
    filtered_matches: Vec<SearchMatch>,
    selected: Option<TargetId>,
    status: Option<String>,
    has_permission: bool,
    snapshot_loaded: bool,
    own_pane_id: Option<u32>,
}

register_plugin!(State);

impl State {
    fn rebuild_matches(&mut self) {
        self.filtered_matches = match self.mode {
            Mode::PaneSwitcher => filter_snapshot(&self.snapshot, &self.query),
            Mode::SessionManager => filter_sessions(&self.snapshot, &self.query),
        };
    }

    fn toggle_mode(&mut self) {
        match self.mode {
            Mode::PaneSwitcher => {
                self.pane_query = self.query.clone();
                self.query = self
                    .session_query
                    .clone()
                    .unwrap_or_else(|| self.pane_query.clone());
                self.session_query = Some(self.query.clone());
                self.mode = Mode::SessionManager;
            }
            Mode::SessionManager => {
                self.session_query = Some(self.query.clone());
                self.query = self.pane_query.clone();
                self.mode = Mode::PaneSwitcher;
            }
        }
        self.rebuild_matches();
        self.normalize_selection();
        self.status = None;
    }

    fn matches(&self) -> &[SearchMatch] {
        &self.filtered_matches
    }

    fn normalize_selection(&mut self) {
        let matches = self.matches();
        if self
            .selected
            .as_ref()
            .is_some_and(|selected| matches.iter().any(|item| item.target() == *selected))
        {
            return;
        }
        let first_match = matches.first().map(SearchMatch::target);
        self.selected = first_match;
    }

    fn move_selection(&mut self, direction: Navigation) {
        let matches = self.matches();
        let current = self
            .selected
            .as_ref()
            .and_then(|selected| matches.iter().position(|item| item.target() == *selected));
        let next_match = next_index(current, matches.len(), direction)
            .and_then(|index| matches.get(index))
            .map(SearchMatch::target);
        self.selected = next_match;
        self.status = None;
    }

    fn dismiss(&mut self) {
        hide_self();
    }

    fn show_switcher(&mut self) {
        // `show_self` focuses the plugin, but does not make the floating layer
        // visible. The latter is per-tab state and may have been hidden by the
        // invoking session.
        let tab_id = self
            .switcher_tab_position
            .and_then(|position| self.tab_ids.get(&position).copied());
        let _ = show_floating_panes(tab_id);
        show_self(true);
    }

    fn current_session_name(&self) -> Option<&str> {
        self.snapshot
            .sessions
            .iter()
            .find(|session| session.live && session.is_current)
            .map(|session| session.name.as_str())
    }

    fn current_panes(&self) -> impl Iterator<Item = &Pane> {
        self.snapshot
            .sessions
            .iter()
            .find(|session| session.live && session.is_current)
            .into_iter()
            .flat_map(|session| session.tabs.iter())
            .flat_map(|tab| tab.panes.iter())
    }

    fn snapshot_origin(&mut self) {
        self.origin_pane = get_focused_pane_info()
            .ok()
            .map(|(_, pane_id)| match pane_id {
                PaneId::Terminal(pane_id) => (false, pane_id),
                PaneId::Plugin(pane_id) => (true, pane_id),
            });
    }

    fn snapshot_floating_context(&mut self) {
        let Some(tab_position) = self.switcher_tab_position else {
            return;
        };
        let Some(&tab_id) = self.tab_ids.get(&tab_position) else {
            return;
        };
        let Some(&was_visible) = self.floating_visibility.get(&tab_position) else {
            return;
        };
        let pane = self
            .current_panes()
            .find(|pane| pane.tab_position == tab_position && pane.is_floating && !pane.is_plugin)
            .map(|pane| (pane.is_plugin, pane.pane_id));
        self.floating_context = Some(FloatingContext {
            tab_id,
            was_visible,
            pane,
        });
    }

    fn restore_floating_context(&mut self, target: Option<(bool, u32)>) {
        let Some(context) = self.floating_context.take() else {
            return;
        };
        if context.pane.is_some() && !context.was_visible && context.pane != target {
            let _ = hide_floating_panes(Some(context.tab_id));
        }
    }

    fn cancel(&mut self) {
        let origin_pane = self.origin_pane.take();
        self.dismiss();
        self.restore_floating_context(None);
        if let Some(origin_pane) = origin_pane {
            if self
                .current_panes()
                .any(|pane| (pane.is_plugin, pane.pane_id) == origin_pane)
            {
                focus_pane(origin_pane);
            }
        }
    }

    fn activate_pane(&mut self, target: TargetId) {
        let TargetId::Pane {
            session_name,
            tab_position,
            pane_id,
            is_plugin,
        } = target
        else {
            self.status = Some("Selected result is not a pane".to_string());
            return;
        };

        if self.current_session_name() == Some(session_name.as_str()) {
            self.origin_pane = None;
            focus_pane((is_plugin, pane_id));
            self.dismiss();
            self.restore_floating_context(Some((is_plugin, pane_id)));
        } else {
            self.origin_pane = None;
            self.floating_context = None;
            self.dismiss();
            switch_session_with_focus(
                &session_name,
                Some(tab_position),
                Some((pane_id, is_plugin)),
            );
        }
        self.status = None;
    }

    fn activate_session(&mut self, session_name: String) {
        self.refresh_snapshot();
        let Some(session) = self
            .snapshot
            .sessions
            .iter()
            .find(|session| session.name == session_name)
        else {
            self.status = Some(format!("Session no longer exists: {session_name}"));
            return;
        };
        if !session.live && session.resurrectable_age.is_none() {
            self.status = Some(format!("Session is no longer available: {session_name}"));
            return;
        }

        self.origin_pane = None;
        self.floating_context = None;
        self.dismiss();
        switch_session_with_focus(&session_name, None, None);
        self.status = None;
    }

    fn activate_selected(&mut self) {
        let Some(selected) = self.selected.clone() else {
            self.status = Some("No result selected".to_string());
            return;
        };
        match selected {
            TargetId::Pane { .. } => self.activate_pane(selected),
            TargetId::Session { session_name } => self.activate_session(session_name),
            TargetId::ResurrectableSession { session_name } => {
                self.origin_pane = None;
                self.floating_context = None;
                self.dismiss();
                switch_session_with_focus(&session_name, None, None);
                self.status = None;
            }
        }
    }

    fn handle_key(&mut self, key: KeyWithModifier) -> bool {
        let modifiers = &key.key_modifiers;
        let has_modifier = |modifier| modifiers.contains(&modifier);
        match key.bare_key {
            BareKey::Char('s') if has_modifier(KeyModifier::Ctrl) => {
                self.toggle_mode();
                true
            }
            BareKey::Tab => {
                self.move_selection(if has_modifier(KeyModifier::Shift) {
                    Navigation::Backward
                } else {
                    Navigation::Forward
                });
                true
            }
            BareKey::Enter => {
                self.activate_selected();
                true
            }
            BareKey::Esc => {
                self.cancel();
                true
            }
            BareKey::Backspace => {
                self.query.pop();
                self.rebuild_matches();
                self.normalize_selection();
                self.status = None;
                true
            }
            BareKey::Char(character)
                if !has_modifier(KeyModifier::Alt)
                    && !has_modifier(KeyModifier::Ctrl)
                    && !has_modifier(KeyModifier::Super)
                    && !character.is_control() =>
            {
                self.query.push(character);
                self.rebuild_matches();
                self.normalize_selection();
                self.status = None;
                true
            }
            _ => false,
        }
    }

    fn open(&mut self) {
        // Session names and resurrectable entries can change while the plugin
        // remains loaded (for example after `zellij action rename-session`).
        // Refresh on every invocation so a stale entry cannot be activated.
        self.refresh_snapshot();
        self.mode = Mode::PaneSwitcher;
        self.query.clear();
        self.pane_query.clear();
        self.session_query = None;
        self.rebuild_matches();
        self.normalize_selection();
        if self.origin_pane.is_none() {
            self.snapshot_origin();
        }
        if self.floating_context.is_none() {
            self.snapshot_floating_context();
        }
        self.show_switcher();
        self.status = None;
    }

    fn handle_message(&mut self, name: String) -> bool {
        match name.as_str() {
            "open" => {
                self.open();
                true
            }
            _ => false,
        }
    }

    fn apply_session_snapshot(
        &mut self,
        live_sessions: Vec<SessionInfo>,
        resurrectable: Vec<(String, Duration)>,
    ) -> bool {
        let own_plugin_id = self
            .own_pane_id
            .or_else(|| Some(get_plugin_ids().plugin_id));
        let live_sessions = live_sessions
            .into_iter()
            .map(|session| SessionData {
                name: session.name,
                is_current: session.is_current_session,
                connected_clients: session.connected_clients,
                tabs: session
                    .tabs
                    .into_iter()
                    .map(|tab| (tab.position, tab.name))
                    .collect(),
                panes: session
                    .panes
                    .panes
                    .into_iter()
                    .flat_map(|(tab_position, panes)| {
                        panes.into_iter().map(move |pane| PaneData {
                            tab_position,
                            pane_id: pane.id,
                            is_plugin: pane.is_plugin,
                            is_floating: pane.is_floating,
                            is_suppressed: pane.is_suppressed,
                            title: pane.title,
                        })
                    })
                    .collect(),
            })
            .collect::<Vec<_>>();
        let next_snapshot = normalize_sessions(&live_sessions, &resurrectable, own_plugin_id);
        let changed = self.snapshot != next_snapshot;
        self.snapshot = next_snapshot;
        self.snapshot_loaded = true;
        self.rebuild_matches();
        self.normalize_selection();
        changed
    }

    fn refresh_snapshot(&mut self) -> bool {
        if !self.has_permission {
            return false;
        }
        match get_session_list() {
            Ok(session_list) => self.apply_session_snapshot(
                session_list.live_sessions,
                session_list.resurrectable_sessions,
            ),
            Err(error) => {
                eprintln!("zellij-pane-switcher: failed to refresh session list: {error}");
                self.status = Some("Could not refresh sessions".to_string());
                false
            }
        }
    }
}

impl ZellijPlugin for State {
    fn load(&mut self, _configuration: BTreeMap<String, String>) {
        subscribe(&[
            EventType::PaneUpdate,
            EventType::TabUpdate,
            EventType::SessionUpdate,
            EventType::Visible,
            EventType::PermissionRequestResult,
            EventType::Key,
        ]);
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
        ]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PaneUpdate(manifest) => {
                if self.own_pane_id.is_none() {
                    self.own_pane_id = Some(get_plugin_ids().plugin_id);
                }
                let new_switcher_tab_position =
                    manifest.panes.iter().find_map(|(tab_position, panes)| {
                        panes
                            .iter()
                            .any(|pane| pane.is_plugin && Some(pane.id) == self.own_pane_id)
                            .then_some(*tab_position)
                    });
                let changed = self.switcher_tab_position != new_switcher_tab_position;
                self.switcher_tab_position = new_switcher_tab_position;
                changed
            }
            Event::TabUpdate(tabs) => {
                let new_tab_ids = tabs.iter().map(|tab| (tab.position, tab.tab_id)).collect();
                let new_floating_visibility = tabs
                    .iter()
                    .map(|tab| (tab.position, tab.are_floating_panes_visible))
                    .collect();
                let changed = self.tab_ids != new_tab_ids
                    || self.floating_visibility != new_floating_visibility;
                self.tab_ids = new_tab_ids;
                self.floating_visibility = new_floating_visibility;
                changed
            }
            Event::SessionUpdate(live_sessions, resurrectable) if self.has_permission => {
                self.apply_session_snapshot(live_sessions, resurrectable)
            }
            Event::SessionUpdate(_, _) => false,
            Event::Visible(visible) => visible && !self.snapshot_loaded && self.refresh_snapshot(),
            Event::PermissionRequestResult(PermissionStatus::Granted) => {
                self.has_permission = true;
                self.refresh_snapshot();
                true
            }
            Event::Key(key) => self.handle_key(key),
            _ => false,
        }
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        self.handle_message(pipe_message.name)
    }

    fn render(&mut self, rows: usize, cols: usize) {
        self.normalize_selection();
        let matches = self.matches();
        let count = matches.len();
        let search = if self.query.is_empty() {
            "type to filter"
        } else {
            &self.query
        };

        let title = match self.mode {
            Mode::PaneSwitcher => "Session and Pane Switcher",
            Mode::SessionManager => "Session Manager",
        };
        println!("\x1b[1;36m╭─ {title}\x1b[0m  \x1b[2m{count} results\x1b[0m");
        println!("\x1b[1;36m│\x1b[0m  \x1b[2mSearch\x1b[0m  \x1b[1;33m[ {search} ]\x1b[0m");
        println!("\x1b[1;36m╰──────────────────────────────────────────────\x1b[0m");

        if matches.is_empty() {
            println!("\x1b[2m  No matching panes or sessions\x1b[0m");
        }

        let mut previous_session = String::new();
        let mut previous_tab = None;
        for matched in matches {
            if previous_session != matched.session_name() {
                if let Some(session) = self
                    .snapshot
                    .sessions
                    .iter()
                    .find(|session| session.name == matched.session_name())
                {
                    let state = if session.live {
                        "live"
                    } else {
                        "resurrectable"
                    };
                    let clients = (session.live)
                        .then_some(format!(
                            ", {} client{}",
                            session.connected_clients,
                            if session.connected_clients == 1 {
                                ""
                            } else {
                                "s"
                            }
                        ))
                        .unwrap_or_default();
                    println!(
                        "\n\x1b[1;36m▸ Session {}\x1b[0m  \x1b[2m{state}{clients}\x1b[0m",
                        session.name
                    );
                }
                previous_session = matched.session_name().to_string();
                previous_tab = None;
            }

            match matched {
                SearchMatch::Session {
                    session_name,
                    live,
                    age,
                    ..
                } => {
                    let target = TargetId::Session {
                        session_name: session_name.clone(),
                    };
                    let marker = if self.selected.as_ref() == Some(&target) {
                        "›"
                    } else {
                        " "
                    };
                    let state = if *live { "live" } else { "resurrectable" };
                    let age = if *live {
                        String::new()
                    } else {
                        format!(", exited {} ago", format_age(*age))
                    };
                    let row = format!("  {marker}  {session_name}  {state}{age}");
                    if self.selected.as_ref() == Some(&target) {
                        println!("\x1b[1;7m{row}\x1b[0m");
                    } else {
                        println!("{row}");
                    }
                }
                SearchMatch::Pane { pane, .. } => {
                    if previous_tab != Some((pane.tab_position, pane.tab_name.clone())) {
                        println!(
                            "\n\x1b[1;35m  ▸ Tab {}\x1b[0m  \x1b[2m{}\x1b[0m",
                            pane.tab_position + 1,
                            if pane.tab_name.trim().is_empty() {
                                format!("Tab {}", pane.tab_position + 1)
                            } else {
                                pane.tab_name.clone()
                            }
                        );
                        previous_tab = Some((pane.tab_position, pane.tab_name.clone()));
                    }
                    let target = pane.target();
                    let marker = if self.selected.as_ref() == Some(&target) {
                        "›"
                    } else {
                        " "
                    };
                    let kind = if pane.is_plugin {
                        "plugin"
                    } else if pane.is_floating {
                        "float"
                    } else {
                        "split"
                    };
                    let hidden = if pane.is_suppressed { " hidden" } else { "" };
                    let row = format!("  {marker}  {kind:<6} {}{hidden}", pane.label());
                    if self.selected.as_ref() == Some(&target) {
                        println!("\x1b[1;7m{row}\x1b[0m");
                    } else {
                        println!("{row}");
                    }
                }
                SearchMatch::ResurrectableSession {
                    session_name, age, ..
                } => {
                    let target = TargetId::ResurrectableSession {
                        session_name: session_name.clone(),
                    };
                    let marker = if self.selected.as_ref() == Some(&target) {
                        "›"
                    } else {
                        " "
                    };
                    let row = format!(
                        "  {marker}    resurrectable, exited {} ago",
                        format_age(*age)
                    );
                    if self.selected.as_ref() == Some(&target) {
                        println!("\x1b[1;7m{row}\x1b[0m");
                    } else {
                        println!("{row}");
                    }
                }
            }
        }

        let status = self.status.as_deref().unwrap_or("");
        if !status.is_empty() {
            println!("\n\x1b[1;33m!\x1b[0m {status}");
        }
        println!(
            "\n\x1b[2mTab/Shift-Tab\x1b[0m navigate  \x1b[2mEnter\x1b[0m activate  \x1b[2mEsc\x1b[0m close  \x1b[2m{rows}×{cols}\x1b[0m"
        );
    }
}

fn format_age(age: Duration) -> String {
    let seconds = age.as_secs();
    if seconds < 60 {
        format!("{seconds}s")
    } else if seconds < 3_600 {
        format!("{}m", seconds / 60)
    } else if seconds < 86_400 {
        format!("{}h", seconds / 3_600)
    } else {
        format!("{}d", seconds / 86_400)
    }
}

fn focus_pane(pane: (bool, u32)) {
    let (is_plugin, pane_id) = pane;
    if is_plugin {
        focus_plugin_pane(pane_id, false, false);
    } else {
        focus_terminal_pane(pane_id, false, false);
    }
}

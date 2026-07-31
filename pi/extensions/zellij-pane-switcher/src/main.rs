mod model;

use model::{filter_panes, next_index, Navigation, Pane, SearchMatch};
use zellij_tile::prelude::*;

use std::collections::BTreeMap;

#[derive(Default)]
struct State {
    panes: Vec<Pane>,
    tabs: BTreeMap<usize, String>,
    query: String,
    selected: Option<(bool, u32)>,
    starred: Option<(bool, u32)>,
    status: Option<String>,
}

register_plugin!(State);

impl State {
    fn matches(&self) -> Vec<SearchMatch> {
        filter_panes(&self.panes, &self.query)
    }

    fn normalize_selection(&mut self) {
        let matches = self.matches();
        if self
            .selected
            .is_some_and(|selected| matches.iter().any(|item| identity(&item.pane) == selected))
        {
            return;
        }
        self.selected = matches.first().map(|item| identity(&item.pane));
    }

    fn move_selection(&mut self, direction: Navigation) {
        let matches = self.matches();
        let current = self.selected.and_then(|selected| {
            matches
                .iter()
                .position(|item| identity(&item.pane) == selected)
        });
        self.selected = next_index(current, matches.len(), direction)
            .and_then(|index| matches.get(index))
            .map(|item| identity(&item.pane));
        self.status = None;
    }

    fn toggle_star(&mut self) {
        let Some(selected) = self.selected else {
            self.status = Some("No pane selected".to_string());
            return;
        };
        self.starred = (self.starred == Some(selected)).then_some(selected);
        self.status = None;
    }

    fn focus_selected(&mut self) {
        let Some(selected) = self.selected else {
            self.status = Some("No pane selected".to_string());
            return;
        };
        focus_pane(selected);
        hide_self();
        self.status = None;
    }

    fn handle_key(&mut self, key: KeyWithModifier) -> bool {
        let modifiers = &key.key_modifiers;
        let has_modifier = |modifier| modifiers.contains(&modifier);
        match key.bare_key {
            BareKey::Tab => {
                self.move_selection(if has_modifier(KeyModifier::Shift) {
                    Navigation::Backward
                } else {
                    Navigation::Forward
                });
                true
            }
            BareKey::Enter => {
                self.focus_selected();
                true
            }
            BareKey::Esc => {
                hide_self();
                true
            }
            BareKey::Backspace => {
                self.query.pop();
                self.normalize_selection();
                self.status = None;
                true
            }
            BareKey::Char(' ')
                if !has_modifier(KeyModifier::Alt)
                    && !has_modifier(KeyModifier::Ctrl)
                    && !has_modifier(KeyModifier::Super) =>
            {
                self.toggle_star();
                true
            }
            BareKey::Char(character)
                if !has_modifier(KeyModifier::Alt)
                    && !has_modifier(KeyModifier::Ctrl)
                    && !has_modifier(KeyModifier::Super)
                    && !character.is_control() =>
            {
                self.query.push(character);
                self.normalize_selection();
                self.status = None;
                true
            }
            _ => false,
        }
    }

    fn focus_starred(&mut self) {
        let Some(starred) = self.starred else {
            show_self(true);
            self.status = Some("No starred pane".to_string());
            return;
        };
        show_self(true);
        focus_pane(starred);
        hide_self();
    }

    fn handle_message(&mut self, name: String) -> bool {
        match name.as_str() {
            "open" => {
                show_self(true);
                self.status = None;
                true
            }
            "focus-starred" => {
                self.focus_starred();
                true
            }
            _ => false,
        }
    }

    fn handle_mouse(&mut self, mouse: Mouse) -> bool {
        let Some((line, _column)) = mouse.position() else {
            return false;
        };
        if !matches!(mouse, Mouse::LeftClick(_, _)) || line < 3 {
            return false;
        }
        let matches = self.matches();
        if let Some(index) = pane_index_at_line(&matches, line) {
            self.selected = Some(identity(&matches[index].pane));
            self.status = None;
            return true;
        }
        false
    }
}

impl ZellijPlugin for State {
    fn load(&mut self, _configuration: BTreeMap<String, String>) {
        subscribe(&[
            EventType::PaneUpdate,
            EventType::TabUpdate,
            EventType::Key,
            EventType::Mouse,
        ]);
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
        ]);
        set_self_mouse_selection_support(true);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PaneUpdate(manifest) => {
                let own_plugin_id = get_plugin_ids().plugin_id;
                self.panes = manifest
                    .panes
                    .into_iter()
                    .flat_map(|(tab_position, panes)| {
                        panes.into_iter().map(move |pane| (tab_position, pane))
                    })
                    .filter(|(_, pane)| !(pane.is_plugin && pane.id == own_plugin_id))
                    .map(|(tab_position, pane)| Pane {
                        tab_position,
                        pane_id: pane.id,
                        is_plugin: pane.is_plugin,
                        title: pane.title,
                    })
                    .filter(|pane| !pane.is_zellij_chrome())
                    .collect();
                self.panes.sort_by_key(Pane::key);
                if let Some(starred) = self.starred {
                    if !self.panes.iter().any(|pane| identity(pane) == starred) {
                        self.starred = None;
                    }
                }
                self.normalize_selection();
                true
            }
            Event::Key(key) => self.handle_key(key),
            Event::Mouse(mouse) => self.handle_mouse(mouse),
            Event::TabUpdate(tabs) => {
                self.tabs = tabs
                    .into_iter()
                    .map(|tab| (tab.position, tab.name))
                    .collect();
                true
            }
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
        println!("\x1b[1;36m◆ Pane Switcher\x1b[0m  \x1b[2m{count} panes\x1b[0m");
        println!(
            "\x1b[2mSearch\x1b[0m  {}",
            if self.query.is_empty() {
                "type to filter"
            } else {
                &self.query
            }
        );
        println!(
            "{}",
            self.status.as_deref().unwrap_or(if matches.is_empty() {
                "No matching panes"
            } else {
                ""
            })
        );
        let mut previous_tab = None;
        for matched in matches {
            if previous_tab != Some(matched.pane.tab_position) {
                let tab_name = self
                    .tabs
                    .get(&matched.pane.tab_position)
                    .filter(|name| !name.trim().is_empty())
                    .cloned()
                    .unwrap_or_else(|| format!("Tab {}", matched.pane.tab_position + 1));
                println!(
                    "\x1b[1;35m╭─ {} · {}\x1b[0m",
                    matched.pane.tab_position + 1,
                    tab_name
                );
                previous_tab = Some(matched.pane.tab_position);
            }
            let pane_id = identity(&matched.pane);
            let selected = if self.selected == Some(pane_id) {
                '›'
            } else {
                ' '
            };
            let starred = if self.starred == Some(pane_id) {
                '★'
            } else {
                ' '
            };
            let kind = if matched.pane.is_plugin { '◆' } else { '•' };
            println!("  {selected} {starred} {kind} {}", matched.pane.label());
        }
        println!(
            "\n\x1b[2mTab/Shift-Tab\x1b[0m navigate  \x1b[2mEnter\x1b[0m focus  \x1b[2mSpace\x1b[0m star  \x1b[2mEsc\x1b[0m close  \x1b[2m{rows}×{cols}\x1b[0m"
        );
    }
}

fn identity(pane: &Pane) -> (bool, u32) {
    (pane.is_plugin, pane.pane_id)
}

fn pane_index_at_line(matches: &[SearchMatch], target_line: usize) -> Option<usize> {
    let mut line = 3;
    let mut previous_tab = None;
    for (index, matched) in matches.iter().enumerate() {
        if previous_tab != Some(matched.pane.tab_position) {
            line += 1;
            previous_tab = Some(matched.pane.tab_position);
        }
        if line == target_line {
            return Some(index);
        }
        line += 1;
    }
    None
}

fn focus_pane(pane: (bool, u32)) {
    let (is_plugin, pane_id) = pane;
    if is_plugin {
        focus_plugin_pane(pane_id, false, false);
    } else {
        focus_terminal_pane(pane_id, false, false);
    }
}

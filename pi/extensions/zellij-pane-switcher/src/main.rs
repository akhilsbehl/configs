mod model;

use model::{filter_panes, next_index, Navigation, Pane, SearchMatch};
use zellij_tile::prelude::*;

use std::collections::BTreeMap;

#[derive(Default)]
struct State {
    panes: Vec<Pane>,
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

    fn handle_mouse(&mut self, mouse: Mouse) -> bool {
        let Some((line, _column)) = mouse.position() else {
            return false;
        };
        if !matches!(mouse, Mouse::LeftClick(_, _)) || line < 3 {
            return false;
        }
        let matches = self.matches();
        if let Some(item) = matches.get(line - 3) {
            self.selected = Some(identity(&item.pane));
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
            Event::TabUpdate(_) => true,
            _ => false,
        }
    }

    fn render(&mut self, rows: usize, cols: usize) {
        self.normalize_selection();
        let matches = self.matches();
        println!("Pane Switcher  {rows}x{cols}");
        println!("Query: {}", self.query);
        println!(
            "{}",
            self.status.as_deref().unwrap_or(if matches.is_empty() {
                "No matching panes"
            } else {
                ""
            })
        );
        for matched in matches {
            let pane_id = identity(&matched.pane);
            let selected = if self.selected == Some(pane_id) {
                '>'
            } else {
                ' '
            };
            let starred = if self.starred == Some(pane_id) {
                '*'
            } else {
                ' '
            };
            println!(
                "{selected}{starred} [{}] {}",
                matched.pane.tab_position + 1,
                matched.pane.label()
            );
        }
        println!("Tab/Shift-Tab move | Enter focus | Space star | Esc hide");
    }
}

fn identity(pane: &Pane) -> (bool, u32) {
    (pane.is_plugin, pane.pane_id)
}

fn focus_pane(pane: (bool, u32)) {
    let (is_plugin, pane_id) = pane;
    if is_plugin {
        focus_plugin_pane(pane_id, false, false);
    } else {
        focus_terminal_pane(pane_id, false, false);
    }
}

mod model;

use model::{filter_panes, Pane};
use zellij_tile::prelude::*;

use std::collections::BTreeMap;

#[derive(Default)]
struct State {
    panes: Vec<Pane>,
    query: String,
    starred: Option<(bool, u32)>,
}

register_plugin!(State);

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
                    if !self
                        .panes
                        .iter()
                        .any(|pane| (pane.is_plugin, pane.pane_id) == starred)
                    {
                        self.starred = None;
                    }
                }
                true
            }
            Event::Key(_) | Event::Mouse(_) | Event::TabUpdate(_) => true,
            _ => false,
        }
    }

    fn render(&mut self, rows: usize, cols: usize) {
        let matches = filter_panes(&self.panes, &self.query);
        println!("Pane Switcher  query: {}", self.query);
        println!("{} panes, {rows}x{cols}", matches.len());
        for matched in matches {
            let marker = if self.starred == Some((matched.pane.is_plugin, matched.pane.pane_id)) {
                '*'
            } else {
                ' '
            };
            println!(
                "{marker} [{}] {}",
                matched.pane.tab_position + 1,
                matched.pane.label()
            );
        }
        println!("Tab/Shift-Tab move | Enter focus | Space star | Esc hide");
    }
}

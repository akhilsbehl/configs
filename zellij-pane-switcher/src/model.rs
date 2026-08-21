use std::time::Duration;

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Pane {
    pub session_name: String,
    pub tab_position: usize,
    pub tab_name: String,
    pub pane_id: u32,
    pub is_plugin: bool,
    pub is_floating: bool,
    pub is_suppressed: bool,
    pub title: String,
}

impl Pane {
    pub fn key(&self) -> (&str, usize, bool, u32) {
        (
            &self.session_name,
            self.tab_position,
            self.is_plugin,
            self.pane_id,
        )
    }

    pub fn target(&self) -> TargetId {
        TargetId::Pane {
            session_name: self.session_name.clone(),
            tab_position: self.tab_position,
            pane_id: self.pane_id,
            is_plugin: self.is_plugin,
        }
    }

    pub fn label(&self) -> String {
        if self.title.trim().is_empty() {
            let kind = if self.is_plugin { "plugin" } else { "terminal" };
            format!("{kind} {}", self.pane_id)
        } else {
            self.title.clone()
        }
    }

    pub fn is_zellij_chrome(&self) -> bool {
        let title = self.title.trim().to_lowercase();
        let title = title.strip_prefix("zellij:").unwrap_or(&title);
        title == "tab-bar"
            || title == "status-bar"
            || title.starts_with("tab-bar ")
            || title.starts_with("status-bar ")
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TabEntry {
    pub position: usize,
    pub name: String,
    pub panes: Vec<Pane>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct SessionEntry {
    pub name: String,
    pub live: bool,
    pub resurrectable_age: Option<Duration>,
    pub is_current: bool,
    pub connected_clients: usize,
    pub tabs: Vec<TabEntry>,
}

#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct Snapshot {
    pub sessions: Vec<SessionEntry>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct SessionData {
    pub name: String,
    pub is_current: bool,
    pub connected_clients: usize,
    pub tabs: Vec<(usize, String)>,
    pub panes: Vec<PaneData>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PaneData {
    pub tab_position: usize,
    pub pane_id: u32,
    pub is_plugin: bool,
    pub is_floating: bool,
    pub is_suppressed: bool,
    pub title: String,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum TargetId {
    Pane {
        session_name: String,
        tab_position: usize,
        pane_id: u32,
        is_plugin: bool,
    },
    Session {
        session_name: String,
    },
    ResurrectableSession {
        session_name: String,
    },
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum SearchMatch {
    Pane {
        pane: Pane,
        score: usize,
    },
    Session {
        session_name: String,
        live: bool,
        connected_clients: usize,
        age: Duration,
        score: usize,
    },
    ResurrectableSession {
        session_name: String,
        age: Duration,
        score: usize,
    },
}

impl SearchMatch {
    pub fn is_live(&self) -> bool {
        match self {
            Self::Pane { .. } => true,
            Self::Session { live, .. } => *live,
            Self::ResurrectableSession { .. } => false,
        }
    }

    pub fn target(&self) -> TargetId {
        match self {
            Self::Pane { pane, .. } => pane.target(),
            Self::Session { session_name, .. } => TargetId::Session {
                session_name: session_name.clone(),
            },
            Self::ResurrectableSession { session_name, .. } => TargetId::ResurrectableSession {
                session_name: session_name.clone(),
            },
        }
    }

    pub fn session_name(&self) -> &str {
        match self {
            Self::Pane { pane, .. } => &pane.session_name,
            Self::Session { session_name, .. } => session_name,
            Self::ResurrectableSession { session_name, .. } => session_name,
        }
    }
}

pub fn filter_sessions(snapshot: &Snapshot, query: &str) -> Vec<SearchMatch> {
    let query = query.trim().to_lowercase();
    let mut matches = snapshot
        .sessions
        .iter()
        .filter_map(|session| {
            contains_case_insensitive(&session.name, &query).map(|score| SearchMatch::Session {
                session_name: session.name.clone(),
                live: session.live,
                connected_clients: session.connected_clients,
                age: session.resurrectable_age.unwrap_or_default(),
                score,
            })
        })
        .collect::<Vec<_>>();
    matches.sort_by(|left, right| {
        right
            .is_live()
            .cmp(&left.is_live())
            .then_with(|| left.session_name().cmp(right.session_name()))
    });
    matches
}

pub fn normalize_sessions(
    live_sessions: &[SessionData],
    resurrectable_sessions: &[(String, Duration)],
    excluded_current_plugin_id: Option<u32>,
) -> Snapshot {
    let mut sessions = live_sessions
        .iter()
        .map(|session| {
            let mut tabs = session
                .tabs
                .iter()
                .map(|(position, name)| TabEntry {
                    position: *position,
                    name: name.clone(),
                    panes: Vec::new(),
                })
                .collect::<Vec<_>>();

            for pane_data in &session.panes {
                if pane_data.is_plugin
                    && (excluded_current_plugin_id == Some(pane_data.pane_id)
                        || pane_data.title.contains("zellij-pane-switcher"))
                {
                    continue;
                }
                let tab_name = session
                    .tabs
                    .iter()
                    .find(|(position, _)| *position == pane_data.tab_position)
                    .map(|(_, name)| name.clone())
                    .unwrap_or_default();
                let pane = Pane {
                    session_name: session.name.clone(),
                    tab_position: pane_data.tab_position,
                    tab_name: tab_name.clone(),
                    pane_id: pane_data.pane_id,
                    is_plugin: pane_data.is_plugin,
                    is_floating: pane_data.is_floating,
                    is_suppressed: pane_data.is_suppressed,
                    title: pane_data.title.clone(),
                };
                if pane.is_zellij_chrome() {
                    continue;
                }
                if let Some(tab) = tabs
                    .iter_mut()
                    .find(|tab| tab.position == pane_data.tab_position)
                {
                    tab.panes.push(pane);
                } else {
                    tabs.push(TabEntry {
                        position: pane_data.tab_position,
                        name: tab_name,
                        panes: vec![pane],
                    });
                }
            }

            for tab in &mut tabs {
                tab.panes
                    .sort_by(|left, right| left.key().cmp(&right.key()));
            }
            tabs.sort_by(|left, right| {
                left.name
                    .cmp(&right.name)
                    .then_with(|| left.position.cmp(&right.position))
            });
            SessionEntry {
                name: session.name.clone(),
                live: true,
                resurrectable_age: None,
                is_current: session.is_current,
                connected_clients: session.connected_clients,
                tabs,
            }
        })
        .collect::<Vec<_>>();

    let live_names = sessions
        .iter()
        .map(|session| session.name.clone())
        .collect::<Vec<_>>();
    for (name, age) in resurrectable_sessions {
        if !live_names.iter().any(|live_name| live_name == name) {
            sessions.push(SessionEntry {
                name: name.clone(),
                live: false,
                resurrectable_age: Some(*age),
                is_current: false,
                connected_clients: 0,
                tabs: Vec::new(),
            });
        }
    }
    sessions.sort_by(|left, right| left.name.cmp(&right.name));
    Snapshot { sessions }
}

pub fn filter_snapshot(snapshot: &Snapshot, query: &str) -> Vec<SearchMatch> {
    let query = query.trim().to_lowercase();
    let mut matches = Vec::new();

    for session in &snapshot.sessions {
        if !session.live {
            let name_score = contains_case_insensitive(&session.name, &query);
            let metadata_score = contains_case_insensitive("resurrectable", &query);
            if let Some(score) = name_score.or(metadata_score) {
                matches.push(SearchMatch::ResurrectableSession {
                    session_name: session.name.clone(),
                    age: session.resurrectable_age.unwrap_or_default(),
                    score,
                });
            }
            continue;
        }

        let session_score = contains_case_insensitive(&session.name, &query);
        for tab in &session.tabs {
            let tab_score = contains_case_insensitive(&tab.name, &query);
            for pane in &tab.panes {
                let pane_score = contains_case_insensitive(&pane.label(), &query);
                let score = match (session_score, tab_score, pane_score) {
                    (Some(score), _, _) => score,
                    (None, Some(score), _) => score + 1_000,
                    (None, None, Some(score)) => score + 2_000,
                    (None, None, None) => continue,
                };
                matches.push(SearchMatch::Pane {
                    pane: pane.clone(),
                    score,
                });
            }
        }
    }

    matches.sort_by(|left, right| {
        right
            .is_live()
            .cmp(&left.is_live())
            .then_with(|| left.session_name().cmp(right.session_name()))
            .then_with(|| match (left, right) {
                (SearchMatch::Pane { pane: a, .. }, SearchMatch::Pane { pane: b, .. }) => a
                    .tab_name
                    .cmp(&b.tab_name)
                    .then_with(|| a.tab_position.cmp(&b.tab_position))
                    .then_with(|| a.key().cmp(&b.key())),
                (SearchMatch::ResurrectableSession { .. }, SearchMatch::Pane { .. }) => {
                    std::cmp::Ordering::Less
                }
                (SearchMatch::Pane { .. }, SearchMatch::ResurrectableSession { .. }) => {
                    std::cmp::Ordering::Greater
                }
                _ => std::cmp::Ordering::Equal,
            })
            .then_with(|| match (left, right) {
                (SearchMatch::Pane { score: a, .. }, SearchMatch::Pane { score: b, .. })
                | (
                    SearchMatch::ResurrectableSession { score: a, .. },
                    SearchMatch::ResurrectableSession { score: b, .. },
                ) => a.cmp(b),
                _ => std::cmp::Ordering::Equal,
            })
    });
    matches
}

fn contains_case_insensitive(label: &str, query: &str) -> Option<usize> {
    label.to_lowercase().find(query)
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum Navigation {
    Forward,
    Backward,
}

pub fn next_index(current: Option<usize>, length: usize, direction: Navigation) -> Option<usize> {
    if length == 0 {
        return None;
    }
    Some(match (current, direction) {
        (None, _) => 0,
        (Some(index), Navigation::Forward) => (index + 1) % length,
        (Some(0), Navigation::Backward) => length - 1,
        (Some(index), Navigation::Backward) => index - 1,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn session(name: &str, current: bool, tabs: &[(&str, &[(&str, u32)])]) -> SessionData {
        SessionData {
            name: name.to_string(),
            is_current: current,
            connected_clients: 1,
            tabs: tabs
                .iter()
                .enumerate()
                .map(|(position, (name, _))| (position, (*name).to_string()))
                .collect(),
            panes: tabs
                .iter()
                .enumerate()
                .flat_map(|(position, (_, panes))| {
                    panes.iter().map(move |(title, pane_id)| PaneData {
                        tab_position: position,
                        pane_id: *pane_id,
                        is_plugin: false,
                        is_floating: false,
                        is_suppressed: false,
                        title: (*title).to_string(),
                    })
                })
                .collect(),
        }
    }

    #[test]
    fn identical_pane_ids_are_qualified_by_session() {
        let snapshot = normalize_sessions(
            &[
                session("a", true, &[("one", &[("shell", 1)])]),
                session("b", false, &[("one", &[("shell", 1)])]),
            ],
            &[],
            None,
        );
        let matches = filter_snapshot(&snapshot, "");
        assert_eq!(matches.len(), 2);
        assert_ne!(matches[0].target(), matches[1].target());
    }

    #[test]
    fn ancestor_matches_include_all_descendant_panes() {
        let snapshot = normalize_sessions(
            &[session(
                "project-api",
                true,
                &[
                    ("Tests", &[("cargo test", 1), ("shell", 2)]),
                    ("Logs", &[("tail", 3)]),
                ],
            )],
            &[],
            None,
        );
        assert_eq!(filter_snapshot(&snapshot, "project").len(), 3);
        assert_eq!(filter_snapshot(&snapshot, "tests").len(), 2);
        assert_eq!(filter_snapshot(&snapshot, "cargo").len(), 1);
    }

    #[test]
    fn search_is_case_insensitive_and_not_subsequence_based() {
        let snapshot = normalize_sessions(
            &[session(
                "Project API",
                true,
                &[("Tests", &[("cargo test", 1)])],
            )],
            &[],
            None,
        );
        assert_eq!(filter_snapshot(&snapshot, "PROJECT").len(), 1);
        assert!(filter_snapshot(&snapshot, "prj").is_empty());
    }

    #[test]
    fn resurrectable_sessions_are_session_only_targets() {
        let snapshot = normalize_sessions(
            &[],
            &[("old-project".to_string(), Duration::from_secs(60))],
            None,
        );
        let matches = filter_snapshot(&snapshot, "old");
        assert_eq!(matches.len(), 1);
        assert_eq!(
            matches[0].target(),
            TargetId::ResurrectableSession {
                session_name: "old-project".to_string()
            }
        );
    }

    #[test]
    fn resurrectable_metadata_is_searchable() {
        let snapshot = normalize_sessions(
            &[],
            &[("old-project".to_string(), Duration::from_secs(60))],
            None,
        );
        assert_eq!(filter_snapshot(&snapshot, "resur").len(), 1);
    }

    #[test]
    fn session_filter_returns_live_sessions_before_resurrectable_sessions_sorted_by_name() {
        let snapshot = normalize_sessions(
            &[
                session("z-live", true, &[("one", &[("shell", 1)])]),
                session("a-live", false, &[("one", &[("shell", 2)])]),
            ],
            &[
                ("z-old".to_string(), Duration::from_secs(60)),
                ("a-old".to_string(), Duration::from_secs(60)),
            ],
            None,
        );
        let matches = filter_sessions(&snapshot, "");
        assert_eq!(
            matches
                .iter()
                .map(SearchMatch::session_name)
                .collect::<Vec<_>>(),
            vec!["a-live", "z-live", "a-old", "z-old"]
        );
    }

    #[test]
    fn pane_filter_returns_live_sessions_before_resurrectable_sessions_sorted_by_name() {
        let snapshot = normalize_sessions(
            &[
                session("z-live", true, &[("one", &[("shell", 1)])]),
                session("a-live", false, &[("one", &[("shell", 2)])]),
            ],
            &[
                ("z-old".to_string(), Duration::from_secs(60)),
                ("a-old".to_string(), Duration::from_secs(60)),
            ],
            None,
        );
        let matches = filter_snapshot(&snapshot, "");
        assert_eq!(matches[0].session_name(), "a-live");
        assert_eq!(matches[1].session_name(), "z-live");
        assert_eq!(matches[2].session_name(), "a-old");
        assert_eq!(matches[3].session_name(), "z-old");
    }

    #[test]
    fn empty_query_returns_deterministic_session_and_tab_name_order() {
        let snapshot = normalize_sessions(
            &[
                session("z", false, &[("one", &[("z", 2)])]),
                session("a", true, &[("two", &[("two", 2)]), ("one", &[("one", 1)])]),
            ],
            &[],
            None,
        );
        let matches = filter_snapshot(&snapshot, "");
        assert_eq!(matches[0].session_name(), "a");
        assert_eq!(
            matches[0].target(),
            TargetId::Pane {
                session_name: "a".to_string(),
                tab_position: 1,
                pane_id: 1,
                is_plugin: false,
            }
        );
    }

    #[test]
    fn navigation_wraps_in_both_directions() {
        assert_eq!(next_index(Some(2), 3, Navigation::Forward), Some(0));
        assert_eq!(next_index(Some(0), 3, Navigation::Backward), Some(2));
        assert_eq!(next_index(None, 3, Navigation::Forward), Some(0));
        assert_eq!(next_index(Some(0), 0, Navigation::Forward), None);
    }

    #[test]
    fn current_switcher_plugin_is_excluded() {
        let mut data = session("a", true, &[("one", &[("shell", 1)])]);
        data.panes.push(PaneData {
            tab_position: 0,
            pane_id: 99,
            is_plugin: true,
            is_floating: true,
            is_suppressed: false,
            title: "plugin - file:/old/zellij-pane-switcher.wasm".to_string(),
        });
        let snapshot = normalize_sessions(&[data], &[], Some(99));
        assert_eq!(filter_snapshot(&snapshot, "").len(), 1);
    }

    #[test]
    fn zellij_chrome_is_excluded_even_with_plugin_suffix() {
        let data = SessionData {
            name: "a".to_string(),
            is_current: true,
            connected_clients: 1,
            tabs: vec![(0, "one".to_string())],
            panes: vec![
                PaneData {
                    tab_position: 0,
                    pane_id: 1,
                    is_plugin: true,
                    is_floating: false,
                    is_suppressed: false,
                    title: "tab-bar (plugin)".to_string(),
                },
                PaneData {
                    tab_position: 0,
                    pane_id: 2,
                    is_plugin: true,
                    is_floating: false,
                    is_suppressed: false,
                    title: "status-bar (plugin)".to_string(),
                },
                PaneData {
                    tab_position: 0,
                    pane_id: 3,
                    is_plugin: true,
                    is_floating: false,
                    is_suppressed: false,
                    title: "zellij:tab-bar".to_string(),
                },
                PaneData {
                    tab_position: 0,
                    pane_id: 4,
                    is_plugin: true,
                    is_floating: false,
                    is_suppressed: false,
                    title: "zellij:status-bar".to_string(),
                },
                PaneData {
                    tab_position: 0,
                    pane_id: 5,
                    is_plugin: false,
                    is_floating: false,
                    is_suppressed: false,
                    title: "shell".to_string(),
                },
            ],
        };
        let snapshot = normalize_sessions(&[data], &[], None);
        assert_eq!(filter_snapshot(&snapshot, "").len(), 1);
    }

    #[test]
    fn empty_titles_have_explicit_fallback_labels() {
        let data = session("a", true, &[("one", &[("", 9)])]);
        let snapshot = normalize_sessions(&[data], &[], None);
        let matches = filter_snapshot(&snapshot, "");
        match &matches[0] {
            SearchMatch::Pane { pane, .. } => assert_eq!(pane.label(), "terminal 9"),
            SearchMatch::ResurrectableSession { .. } | SearchMatch::Session { .. } => {
                panic!("expected pane")
            }
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Pane {
    pub tab_position: usize,
    pub pane_id: u32,
    pub is_plugin: bool,
    pub title: String,
}

impl Pane {
    pub fn key(&self) -> (usize, bool, u32) {
        (self.tab_position, self.is_plugin, self.pane_id)
    }

    pub fn label(&self) -> String {
        if self.title.trim().is_empty() {
            let kind = if self.is_plugin { "plugin" } else { "terminal" };
            format!("{kind} {}", self.pane_id)
        } else {
            self.title.clone()
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct SearchMatch {
    pub pane: Pane,
    pub score: usize,
}

pub fn filter_panes<'a>(panes: &'a [Pane], query: &str) -> Vec<SearchMatch> {
    let query = query.trim().to_lowercase();
    let mut matches = panes
        .iter()
        .filter_map(|pane| {
            subsequence_score(&pane.label(), &query).map(|score| SearchMatch {
                pane: pane.clone(),
                score,
            })
        })
        .collect::<Vec<_>>();

    matches.sort_by(|left, right| {
        left.score
            .cmp(&right.score)
            .then_with(|| left.pane.key().cmp(&right.pane.key()))
    });
    matches
}

fn subsequence_score(label: &str, query: &str) -> Option<usize> {
    if query.is_empty() {
        return Some(0);
    }

    let label = label.to_lowercase();
    let mut query_chars = query.chars();
    let mut next_query = query_chars.next()?;
    let mut score = 0;
    let mut previous_index = None;

    for (index, character) in label.chars().enumerate() {
        if character != next_query {
            continue;
        }

        score += match previous_index {
            None => index,
            Some(previous) if previous + 1 == index => 0,
            Some(previous) => index - previous,
        };
        previous_index = Some(index);

        match query_chars.next() {
            Some(character) => next_query = character,
            None => return Some(score),
        }
    }

    None
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

    fn pane(tab_position: usize, pane_id: u32, title: &str) -> Pane {
        Pane {
            tab_position,
            pane_id,
            is_plugin: false,
            title: title.to_string(),
        }
    }

    #[test]
    fn empty_query_returns_all_panes_in_deterministic_order() {
        let panes = vec![pane(1, 2, "two"), pane(0, 1, "one")];
        let matches = filter_panes(&panes, "");
        assert_eq!(matches[0].pane.pane_id, 1);
        assert_eq!(matches[1].pane.pane_id, 2);
    }

    #[test]
    fn query_matches_pane_labels_only() {
        let panes = vec![pane(0, 1, "workspace"), pane(3, 2, "shell")];
        assert_eq!(filter_panes(&panes, "wrk").len(), 1);
        assert_eq!(filter_panes(&panes, "tab").len(), 0);
    }

    #[test]
    fn contiguous_and_prefix_matches_rank_first() {
        let panes = vec![pane(0, 1, "workspace"), pane(0, 2, "w x o r k")];
        let matches = filter_panes(&panes, "work");
        assert_eq!(matches[0].pane.pane_id, 1);
    }

    #[test]
    fn navigation_wraps_in_both_directions() {
        assert_eq!(next_index(Some(2), 3, Navigation::Forward), Some(0));
        assert_eq!(next_index(Some(0), 3, Navigation::Backward), Some(2));
        assert_eq!(next_index(None, 3, Navigation::Forward), Some(0));
        assert_eq!(next_index(Some(0), 0, Navigation::Forward), None);
    }

    #[test]
    fn empty_titles_have_explicit_fallback_labels() {
        assert_eq!(pane(0, 9, "").label(), "terminal 9");
    }
}

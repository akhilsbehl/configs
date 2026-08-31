#!/usr/bin/env bash

npx skills update

rm -rf ask-matt/
rm -rf code-review/
rm -rf codebase-design/
rm -rf diagnosing-bugs/
rm -rf grill-me/
rm -rf handoff/
rm -rf research/
rm -rf tdd/
rm -rf to-questionnaire/
rm -rf wait-what/
rm -rf wizard/
rm -rf writing-for-agents/

unlink ~/.pi/agent/skills/ask-matt
unlink ~/.pi/agent/skills/code-review
unlink ~/.pi/agent/skills/codebase-design
unlink ~/.pi/agent/skills/diagnosing-bugs
unlink ~/.pi/agent/skills/grill-me
unlink ~/.pi/agent/skills/handoff
unlink ~/.pi/agent/skills/research
unlink ~/.pi/agent/skills/tdd
unlink ~/.pi/agent/skills/to-questionnaire
unlink ~/.pi/agent/skills/wait-what
unlink ~/.pi/agent/skills/wizard
unlink ~/.pi/agent/skills/writing-for-agents
unlink ~/.agents/skills/setup-matt-pocock-skills/issue-tracker-gitea.md

ln -s ~/configs/skills/issue-tracker-gitea.md ~/.agents/skills/setup-matt-pocock-skills/issue-tracker-gitea.md
cat ~/configs/skills/gitea-addendum-mp-skill-setup.md >> ~/.agents/skills/setup-matt-pocock-skills/SKILL.md
cat ~/configs/skills/grilling-addendum.md >> ~/.agents/skills/grilling/SKILL.md

exit $?

@echo off

git submodule update --remote system
git add system
git commit -m "chore: update system"
git push

pause
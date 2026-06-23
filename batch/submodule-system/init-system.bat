@echo off

git submodule add https://github.com/AntoineBoulet/sites-commons.git system
git add .gitmodules system
git commit -m "chore: add submodule system"
git push

pause
# DEVELOPMENT WORKFLOW TOOLS
# Compile elm code automatically 
ls *.elm | entr -s 'elm-make main.elm --output=../static/js/app.js'
ls *.elm | entr -s 'reload-browser Chrome' > /dev/null

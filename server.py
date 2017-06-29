#!venv/bin/python 
from flask import Flask, render_template, request, jsonify

app = Flask(__name__)

@app.route("/")
def index():
    return render_template('index.html')


@app.route("/signup", methods =["POST","GET"])
def signup():
    allUserNames = ["admin","usuario","user"]
    allUserEmails = ["d@gmail.com","a@gmail.com"]
    isValidPassword = lambda p : True if len(p) >= 6 else False 

    if request.method == "POST":
        userName = request.form['user_name']
        userPass = request.form['user_passwd']
        userEmail = request.form['user_mail'] if 'user_mail' in request.form else None

        if userEmail in allUserEmails or userName in allUserNames:
            return jsonify(dict(status="fail", message="Account already exists"))

        if not isValidPassword(userPass):
            return jsonify(dict(status="error", message="Please choose a password with at least ..."))

        #Redirect to some page
        return jsonify(dict(status="ok", data="Account created succesfully"))
    else:
        return render_template('index.html')

    return jsonify(dict(status="error", message="Couldnt create account"))

    


if __name__ == "__main__":
    app.run(host="0.0.0.0", debug = True, threaded = True)

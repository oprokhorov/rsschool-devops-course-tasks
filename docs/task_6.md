## Requirements
- Free SonarQube Cloud account (For security check pipeline step)
- helm is installed
- mikikube is up and running

### Create SonarQube Cloud account

Task requires running SonarQube security check in Jenkins pipeline, for this we need to create a free SonarQube Cloud account and generate a token.

1. Go to: https://sonarcloud.io

2. Sign in with GitHub to start a 14 free trial for SonarQube Cloud.

3. Select "Import organization from  GitHub", if you are a member of several orgs on GitHub, select the one that hosts repository for current task

4. Authorize the access to current repository

5. Select Free plan and click "Create organization"

6. Select your sschool-devops-course-tasks repository and click "Set up" 

7. Select "Previous version" and click "Create Project" in "Clean as You Code" methodology configuration (whatever that is)

8. Go to MY Account > Security > and generate a new token, give it a name "Jenkins" and save the secret in your password manager

Linking GitHub repo will automatically run SonarQube check against any open PR's.

<!-- ### Configure secrets

Our Jenkins pipeline will authenticate with several external services, for this we need to configure necessary credentials.

```
cp .env.example .env
```

Open .env file, provide actual credentials and save the file

```
DOCKERHUB_TOKEN=ReplaceWithYourDockerHubToken
SONARQUBE_TOKEN=ReplaceWithYourSonarQubeToken
``` -->


### Install Jenkins

Checkout the repository

Open powershell console and run the script

```powershell
.\jenkins\install-jenkins.ps1
```

When script finishes running, Crl+Click the URL it returns, and authenticate with the username admin and passsword form the outputs.

### Add credentials (manual)

Go to "Jenkins Dashboard" > "Manage Jenkins" > "Credentials" > "System" > "Global credentials (unrestricted)" >  "Add Credentials":

```
- Kind: Secret text
- Scope: Global
- Secret: [paste your SonarCloud token here]
- ID: sonarcloud-token
- Description: SonarCloud authentication token
```

Click create

The same way create Dockerhub credentials:

```
- Kind: Username with password
- Scope: Global
- Username: [paste your Dockerhub username here]
- Password: [paste your Dockerhub password here]
- ID: dockerhub-credentials
- Description: Dockerhub credentials
```

Create Discord Webhook:

Go to your Discord server settings
Navigate to Integrations → Webhooks
Click "New Webhook"
Copy the webhook URL


Add Jenkins Credential:

```
- Kind: Secret text
- Scope: Global
- Secret: [paste your Discord Webhook URL here]
- ID: discord-webhook-url
- Description:  Discord Webhook URL
```

Install Discord Notifier Plugin:

Go to Jenkins → Manage Jenkins → Manage Plugins
Search for "Discord Notifier" and install it

### Add the Pipeline to Jenkins

Go to Dashboard > New Item > Pipeline

Configure parameters:
- Enter an item name: `flask-hello-SCM`
- Pipeline:
    - SCM: `Git`
    - Repository URL: `https://github.com/oprokhorov/rsschool-devops-course-tasks.git`
    - Credentials: `none`
    - Branches to build: `*/task_6`
    - Script Path: `jenkins/Jenkinsfile`

Click Save

Run the pipeline manually one time so it downloads the Jenkinsfile with poll SCM trigger. Next pushes will happen automatically.

### Run the pipeline

Pipeline is configured to poll the repository every 2 minutes, and it will run if there were changes. Alternatively, you can manually trigger the build from the Jenkins web GUI.

Make a commit to the repo, wait 2 minutes, see that pipeline gets griggered, verify that it passes and sends notification to your Discord server.

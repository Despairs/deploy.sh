#!/bin/bash
deploy() {
  CONFIG="/home/dev/deploy.yml"

  PROJECT=$(yq '.project[].name' $CONFIG | gum choose)
  [[ -z $PROJECT ]] && return 1

  APP=$(yq ".project[] | select (.name == \"$PROJECT\") | .app[].name" $CONFIG | gum choose)
  [[ -z $APP ]] && return 1

  JARS_PATH=$(yq ".project[] | select (.name == \"$PROJECT\") | .app[] | select (.name == \"$APP\") | .path" $CONFIG)
  JARS_IN_PATH=$(find "$JARS_PATH" -name '*.jar')
  [[ -z $JARS_IN_PATH ]] && echo "Error: there is no *.jar files inside $JARS_PATH" && return 1

  JAR=$(gum choose "$JARS_IN_PATH")
  [[ -z $JAR ]] && return 1

  JAR_NAME=$(echo "$JAR" | perl -ane 'print $1 if /.*target\/(.*)/')

  readarray -t ENV < <(yq ".project[] | select (.name == \"$PROJECT\") | .env[].name" $CONFIG | gum choose --no-limit)
  [[ ${#ENV[@]} -eq 0 ]] && return 1

  printf -v COMMA_ENV "\'%s'," "${ENV[@]}"
  gum confirm "Do you really want to deploy '$JAR_NAME' to environments: ${COMMA_ENV::-1}?" || return 0

  START_AFTER_DEPLOY=0
  gum confirm "Do you want to start '$JAR_NAME' via 'start-app.sh'?" && START_AFTER_DEPLOY=1

  for E in "${ENV[@]}"; do
    SSH_HOST=$(yq ".project[] | select (.name == \"$PROJECT\") | .env[] | select (.name == \"$E\") | .host" $CONFIG)
    SSH_USER=$(yq ".project[] | select (.name == \"$PROJECT\") | .env[] | select (.name == \"$E\") | .user" $CONFIG)
    SSH_PATH=$(yq ".project[] | select (.name == \"$PROJECT\") | .env[] | select (.name == \"$E\") | .path.app" $CONFIG)
    SSH_KEY=$(yq ".project[] | select (.name == \"$PROJECT\") | .env[] | select (.name == \"$E\") | .private-key" $CONFIG)

    DEPLOY_COMMAND="scp -i $SSH_KEY $JAR $SSH_USER@$SSH_HOST:$SSH_PATH/$JAR_NAME"
    echo "$DEPLOY_COMMAND" | bash -x

    [[ $START_AFTER_DEPLOY -eq 1 ]] && {
      SSH_START_APP_PATH=$(yq ".project[] | select (.name == \"$PROJECT\") | .env[] | select (.name == \"$E\") | .path.start-app" $CONFIG)
      APP_NAME="${JAR_NAME%%-[0-9]*}"
      APP_VERSION="${JAR_NAME#$APP_NAME-}"
      APP_VERSION="${APP_VERSION%.jar}"

      START_COMMAND="ssh -i $SSH_KEY $SSH_USER@$SSH_HOST $SSH_START_APP_PATH/start-app.sh -n=$APP_NAME -v=$APP_VERSION -f"
      echo "$START_COMMAND" | bash -x
    }
  done
}

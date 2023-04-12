export SERVICE_URL=https://europe-west1-$PROJECT.cloudfunctions.net/$APP_NAME_SHORT-gcf-$MODULE_NAME_SHORT-ew1-$PROJECT_ENV

export IDENTITY=$APP_NAME_SHORT-sa-$MODULE_NAME_SHORT-$PROJECT_ENV@$PROJECT.iam.gserviceaccount.com

export TIMEOUT=300

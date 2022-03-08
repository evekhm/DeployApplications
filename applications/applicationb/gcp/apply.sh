#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DB="CDS-Library.zip"
ZIP="${DIR}/$DB"

# Requires following settings in the Project->Settings->CI/CD
# CDS_LIBRARY_TOKEN: Access Token generated for the access to the sources of the CDS-Library Project
#
# SERVICE_ACCOUNT_FILE: Jso File saved as a CI/CD Variable of type File, downloaded for the GCP project as a key of the Service Account.
create_CDS_Library_zip(){
  echo "Creating new CDS-Library Archive ... "
  PWD=$(pwd)

  cd "$DIR"/..
  zip --exclude '*.git*' -r -q "$ZIP" CDS-Library
  cd "$PWD" || exit
}

create_bucket(){
  echo "Preparing Cloud Storage [${BUCKET}] bucket..."
  if gsutil ls | grep "${BUCKET}"; then
      echo "Bucket [$BUCKET] already exists - skipping step" INFO
  else
      echo "Creating GCS bucket for pipeline: [$BUCKET]..." INFO
      gsutil mb -p "$PROJECT_ID" "${BUCKET}"/
  fi
#  gsutil iam ch  "serviceAccount:$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com":objectViewer "${BUCKET}"
  gsutil cp "${ZIP}" "$BUCKET"/"$DB"
}

echo "***** Applying  $APPLICATION deployment  *****"
echo ${CI_PROJECT_DIR} $GSA_NAME $BUCKET $PROJECT_ID
if [ -z $CDS_LIBRARY_TOKEN ]; then
  echo "Error: CDS_LIBRARY_TOKEN is not set for access to the CDS-Library project"
  exit 1;
fi

apt-get update && apt-get install git
apt-get install zip unzip -q

gcloud auth activate-service-account --key-file ${SERVICE_ACCOUNT_FILE} --project=$PROJECT_ID

# Deploys CDS-Library, requires CDS_LIBRARY_TOKEN in the Settings
# Get CDS-Library from GitLab repo, zips and uploads into the GCP Cloud Storage Bucket
git clone https://"${CI_DEPLOY_USER}":"${CI_DEPLOY_PASSWORD}"@gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/CDS-Library.git ${CI_PROJECT_DIR}/../CDS-Library
create_bucket
create_CDS_Library_zip
#
#GSA_NAME=$GSA_NAME PROJECT_ID=$PROJECT_ID BUCKET=$BUCKET bash ${CI_PROJECT_DIR}/deploy_CDS_Library.sh






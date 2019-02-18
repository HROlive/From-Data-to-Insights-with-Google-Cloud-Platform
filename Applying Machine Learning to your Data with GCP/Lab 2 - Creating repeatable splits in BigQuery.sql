# Launch Cloud Datalab

-- Activate Cloud Shell - gcloud compute zones list (These are the regions that
-- currently support Cloud ML Engine jobs: us-east1, us-central1, asia-east1, 
-- europe-west1. List with the updated regions available 
-- https://cloud.google.com/ml-engine/docs/environment-overview#cloud_compute_regions)

-- datalab create mydatalabvm --zone <ZONE> - Web Preview - Change port to 8081

# If the cloud shell used for running the datalab command is closed or interrupted, the 
# connection to your Cloud Datalab VM will terminate. If that happens, you may be able to
# reconnect using the command ‘datalab connect mydatalabvm' in your new Cloud Shell.

# Clone course repo within your Datalab instance

# %bash
# git clone https://github.com/GoogleCloudPlatform/training-data-analyst
# rm -rf training-data-analyst/.git

#Creating Repeatable Dataset splits

-- datalab - notebooks - training-data-analyst - courses - machine_learning - deepdive -
-- 02_generalization - repeatable_splitting.ipynb

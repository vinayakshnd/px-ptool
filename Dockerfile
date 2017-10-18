FROM python:2.7

RUN mkdir -p /root/px_prov /root/.ssh && cd /root/px_prov
ADD https://releases.hashicorp.com/terraform/0.10.7/terraform_0.10.7_linux_amd64.zip /usr/bin
RUN apt-get update && apt-get install unzip
RUN cd /usr/bin && unzip terraform_0.10.7_linux_amd64.zip && chmod 755 terraform
COPY keys/id* /root/.ssh/
COPY . /root/px_prov/
WORKDIR /root/px_prov
RUN pip install -r requirements.txt && chmod 755 px_provision.py
ENV TF_VAR_do_token '____YOUR_DO_TOKEN____'
ENV DO_PUBKEY_FP "_FINGERPRINT_OF_KEY_IN_DO_"
ENV TF_VAR_azure_subscription_id "_AZURE_SUB_ID_"
ENV TF_VAR_azure_client_id "_AZURE_CLIENT_ID_"
ENV TF_VAR_azure_client_secret "_AZURE_CLIENT_SECRET_"
ENV TF_VAR_azure_tenant_id "_AZURE_TENANT_ID_"
ENV TF_VAR_aws_access_key "__AWS_ACCESS_KEY__"
ENV TF_VAR_aws_secret_key "__AWS_SECRET_KEY__"
ENV TF_VAR_aws_key "__AWS_KEY_NAME__"
ENV GCP_PROJECT '_GCP_PROJECT_ID_'
ENV GCP_SA_JSON '_CONTENTS_OF_GCP_SERVICE_ACCOUNT_JSON_FILE_'
CMD python px_provision.py

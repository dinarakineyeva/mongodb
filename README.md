### MongoDB Atlas

If you don't already have a Atlas account, [sign up here](https://www.mongodb.com/cloud/atlas/register).
If you are prompted to create a database, look for the "I'll do this later" link
in the lower left corner. Once you're logged in, click on "Access Manager" at
the top and select "Organization Access".

Select the "API Keys" tab and click the "Create API Key" button. Give your new
key a short description and select the "Organization Owner" permission. Click
"Next" and then make a note of your public and private keys. This is your last
chance to see the private key, so be sure you've written it down somewhere safe.

Next, you'll need your Organization ID. Go to [the projects page](https://cloud.mongodb.com/v2#/org)
and click "Settings" in the list on the left side of the window to get to the
Organization Settings screen. Your organization ID is in a box in the upper-left
corner of the window. Copy your Organization ID and save it with your credentials.




### Configuring the demo

If you haven't already, clone this repo. Run `terraform init` to make sure
Terraform is working correctly and download the provider plugins.

Then, create a file in the root of the repository called `varables.tf` with
the following contents, replacing placeholders as necessary:

    atlas_pub_key          = "<your Atlas public key>"
    atlas_priv_key         = "<your Atlas private key>"
    atlas_org_id           = "<your Atlas organization ID>"



If you selected the `us-central1`/`US_CENTRAL` region then you're ready to go. If
you selected a different region, add the following to your `variables.tf` file:

    atlas_cluster_region = "<Atlas region ID>"

Run `terraform init` again to make sure there are no new errors. If you get an
error, check your `variables.tf` file.

### Run it!

You're ready to deploy! You have two options: you can run `terraform plan` to
see a full listing of everything that Terraform wants to do without any risk of
accidentally creating those resources. If everything looks good, you can then
run `terraform apply` to execute the plan.

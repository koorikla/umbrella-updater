# Helm Dependency Updater

This script automates the process of updating Helm chart dependencies to their latest versions.

## Prerequisites

- [Docker](https://www.docker.com/)

## Usage

1. Clone this repository:

   ```shell
   git clone https://github.com/your-username/helm-dependency-updater.git

2. Change to the cloned directory:

   ```shell
   cd helm-dependency-updater

3. Run the following command to build the Docker image:

   ```shell
   docker build -t umbrella-updater .

4. Run the following command to update the dependencies:

   ```shell
   docker run -v ./charts/app/Chart.yaml:/usr/local/bin/charts/app/Chart.yaml -v ./temp:/usr/local/bin/temp umbrella-updater   


The script will add the Helm repositories specified in Chart.yaml, update the repositories, download the latest dependencies, and generate values-current.yaml and values-new.yaml files in the temp directory.

### If there are differences between the current and new values files, the script will print a warning.
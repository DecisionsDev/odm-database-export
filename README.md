# ODM Decision Center database export utility


## Features
This web application creates a compressed (.zip) file that contains the contents of a Decision Center repository. Optionally, the application can exclude the rule definitions to address privacy concerns while still reproducing most repository issues. The application must be deployed on the server that contains Decision Center data source. It can typically be deployed alongside Decision Center.

## Requirements
- This web application is installed along side ODM Decision Center see [this technote](https://www.ibm.com/support/pages/decision-center-database-export-utility) for details.

## Deployment
- For Operational Decicion Manager **before 9.5** use [this implementation](https://github.ibm.com/odm-l3-services/odm-database-export/raw/refs/heads/main/resources/javaEE/decisioncenter-dbdump.war)
- For Operational Decision Manager **since 9.5** use [this implementation](https://github.ibm.com/odm-l3-services/odm-database-export/raw/refs/heads/main/resources/jakartaEE/decisioncenter-dbdump.war)

# Issues and contributions
For issues relating specifically to this repository, please use the [GitHub issue tracker](../../issues).
We welcome contributions following [our guidelines](CONTRIBUTING.md).

# License
The code found in this project are licensed under the [Apache License 2.0](LICENSE).

# Notice
© Copyright IBM Corporation 2025.

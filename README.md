# codeCleanse
codeCleanse aims to automate sophisticated code cleanup process. 

**Version 1.0.0**

Label Validator menu
- Check duplicate values within CustomLabels.labels [1]
- Check all unused labels in complete Repository (pages, classes and lwc) [2]
- Check all labels imported from other repositories [3]
- Check all unused imported Labels in LWC Components [4]

Assumptions
- <fullName>...</fullName> tags are in single line
- <value>...</value> tags are in single line
- *.js-meta.xml prefix is component directory name

Notes
- Before fixing duplicate labels, check if they are already part of managed package.
- Before fixing unused labels, check if other repositories are dependent on it.

# Output

codeCleanse.ouput is Sample report 

# command line usage

`$ ./codeCleanse.sh [menu | fix] [1 | 2 | 3 | 4]`

# Example 1


```#!/bin/sh
# Below usage will execute only Label Validator 4th option
$ ./codeCleanse.sh menu 4
```

# Example 2


```#!/bin/sh
# Below usage will fix Label Validator 4th option
$ ./codeCleanse.sh fix 4
```

---

## Contributors

- Shivam Gupta <shivamgupta@salesforce.com>

---

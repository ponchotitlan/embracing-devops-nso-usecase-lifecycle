# rfs_common package
This is a dummy rfs package to demonstrate standarized services development environments. Service packages of this sorts are normally used for the following:

- Hosting commonly used python utilities (IP address converters, data parsers, etc)
- Environment variables deployed on CDB for other packages to use
- Data Model wrapper for grouping of the available rfs services within the NSO node

## Addition to other rfs packages
To use the resources within this rfs, including the data model wrapping, first this package needs to be mentioned in the file ```package-meta-data.xml```   located in the root of the project with the following syntax:

```
  <required-package>
    <name>rfs-common</name>
  </required-package>
```

Additionally, the data model of the target service needs to be augmented in the following way:
```
  augment /rfs-common:rfs/rfs-common:services {
    container myNewService {
      /****/
    }
  }
```

The usability of this service in NSO CLI would be the following:
```
> rfs services myNewService ...(...)
```

---

Crafted with 🧡  by [Alfonso Sandoval - Cisco](https://linkedin.com/in/asandovalros)
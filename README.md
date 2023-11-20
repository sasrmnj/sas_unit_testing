# SAS Unit testing

Welcome to "another" SAS Unit Testing framework. This library provides a set of ready-to-use macro functions to automate the testing and validation of SAS scripts.

You can use the framework in just two lines of SAS code:

```sas
filename utf url "https://raw.githubusercontent.com/jrsas/sas_unit_testing/main/unit_testing.sas";
%include utf;
```

This framework is written in pure SAS, thus it is OS independent.

## Components

### docs folder

This folder groups all the [documentation](./docs/index.md) of this framework

### core folder

This folder groups all the main components of the framework: initialization procedures, reporting procedures, helper functions...

### asserts folder

This folder groups all the functions to perform unit testing.

### tests folder

This folder contains all the stuff to validate the framework. Obviously, the framework is validated by itself!

## Installation

First, download the repository to a location your SAS system can access.
Then, include the framework like this:
```sas
*-- Include the unit testing framework --*;
%include "/.../sas_unit_testing.sas";
```

Alternatively, you can just refer the framework from the main repository like this:
```sas
filename utf url "https://raw.githubusercontent.com/jrsas/sas_unit_testing/main/unit_testing.sas";
%include utf;
```

## Standards

### File Properties

- filenames much match macro names
- filenames must be lowercase, without spaces
- macro names must be lowercase
- one macro per file
- `ut_` prefixes for **u**nit **t**esting macro functions
- follow verb-noun convention
- UTF-8

### Header Properties

So far, I decided to not use any documentation tool. However, I recommend to document each macro function this way:
Right under the `%macro` key word, create a comment block with
1) Short descriptino of the macro function
2) One line per macro function parameter in format `param name: param description`

### Coding Standards

- indentation = 4 spaces. No tabs!
- no trailing white space
- no invisible characters, other than spaces. If invisibles are needed, use hex literals.
- macro variables should have the trailing dot (`&var.` not `&var`)
- the closing `%mend` should contain the macro name.
- where global macro variables are necessary, prefix them with the `ut_` value
- Use the official SAS language extension for VS code

## General Notes

- all macros should be compatible with SAS versions from support level B and above (so currently 9.2 and later). If an earlier version is not supported, then  document it in the header and exit gracefully (eg `%if %sysevalf(&sysver<9.2) %then %return`).

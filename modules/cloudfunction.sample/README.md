# README - Sample module for Google Cloud Function (http single route)

## Purpose

This document aims to give information on the current module which is dedicated
to be a base template for building a "single route" HTTP cloud function.
If you plan on building  multiple routes REST API, consider using the GCR template instead.

*Caution* this template is only suitable for [HTTP-triggered cloud functions](https://cloud.google.com/functions/docs/writing/http).
Do not use to deploy [Background functions](https://cloud.google.com/functions/docs/writing/background) whose implementation are different.

## Module description

### Architecture

This module contains the implementation of a sample cloud function. It is based
on the use of `functions_framework` library.

The function entrypoint is the `main` method of `src/main.py` file.

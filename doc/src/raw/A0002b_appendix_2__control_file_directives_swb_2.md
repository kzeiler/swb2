## Control File Directives {#appendix_2_control_file_directives_version_2}

[TOC]

This section provides a complete list of the control file statements understood by SWB, version 2.0.

## Control File Directives: Gridded Datasets

SWB has a set of common control file directives that may be used with any input gridded dataset. The types of data recognized by SWB (as of July 2015) includes:

|Gridded Dataset Name           |
|-------------------------------|
| PRECIPITATION                 |
| TMIN                          |
| TMAX                          |
| AVAILABLE_WATER_CONTENT       |
| POTENTIAL_ET                  |
| SOLAR_RADIATION               |
| WIND_SPEED                    |
| RAINFALL_ZONE                 |
| FLOW_DIRECTION                |
| FOG_RATIO                     |
| LAND_USE                      |
| SOILS_GROUP                   |
| INITIAL_PERCENT_SOIL_MOISTURE |
| INITIAL_SNOW_COVER_STORAGE    |
| CANOPY_COVER_FRACTION         |
| PERVIOUS_SURFACE_FRACTION     |
| IMPERVIOUS_SURFACE_FRACTION   |
| STEMFLOW_FRACTION             |
| EVAPORATION_TO_RAINFALL_RATIO |
| RAINFALL_ADJUST_FACTOR        |
| CESSPOOL_LEAKAGE              |
| STORM_DRAIN_LEAKAGE           |
| WATER_BODY_LEAKAGE            |
| WATER_MAIN_LEAKAGE            |
| DISPOSAL_WELL_DISCHARGE       |
| ANNUAL_DIRECT_RECHARGE_RATE   |
| RUNOFF_ZONE                   |
| IRRIGATION_MASK               |
| RELATIVE_HUMIDITY             |

For each of the gridded datasets listed above, a standard set of suffixes may be added to the dataset name to control how SWB treats the dataset. The list of suffixes understood by SWB is long:

| Suffix                             | Argument         | Description                             |
|------------------------------------|------------------|-----------------------------------------|
| _SCALE_FACTOR                      |  *real value*    | amount to multiply raw grid value by prior to use |
| _ADD_OFFSET                        |  *real value*    | amount to add to the raw grid value following application of the scale factor, if any |
| _NETCDF_X_VAR                      |  *string*        | name of the variable to be used as the "x" axis |
| _NETCDF_Y_VAR                      |  *string*        | name of the variable to be used as the "y" axis |
| _NETCDF_Z_VAR                      |  *string*        | name of the variable to be used as the "z" (value) axis |
| _NETCDF_TIME_VAR                   |  *string*        | name of the variable to be used as the "time" axis |
| _NETCDF_VARIABLE_ORDER             |  "xyt or txy"    | description of the order in which the gridded data were written |
| _NETCDF_FLIP_VERTICAL              |  **none**        | if present, all gridded data will be "flipped" around the vertical axis. |
| _NETCDF_FLIP_HORIZONTAL            |  **none**        | if present, all gridded data will be "flipped" around the horizontal axis  |
| _NETCDF_MAKE_LOCAL_ARCHIVE         |  |
| _PROJECTION_DEFINITION             |  | PROJ.4 string describing the geographic projection of the dataset
| _MINIMUM_ALLOWED_VALUE             | *real value* | ceiling to be applied to the data; data above this value will be reset to this amount
| _MAXIMUM_ALLOWED_VALUE             | *real value* | floor to be applied to the data; data beneath this value will be reset to this amount   
| _MISSING_VALUES_CODE               | *real or integer value* | value   
| _MISSING_VALUES_OPERATOR           | "<", "<=", ">", ">=" |
| _MISSING_VALUES_ACTION             | "mean" or "zero" | "mean" will substitute the mean value calculated over the remaining valid cells; "zero" will substitute a value of 0.0 in place of missing values

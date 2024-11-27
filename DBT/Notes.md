### A. Setup Project
---
---
- dbt init
    - Fill all the Parameters (To Connect DBT-Snowflake)
- Pre-requisities:
    - 1 Database: 
        - 3 Schemas: (Layers)
            1. [Landing] (Low-Layer)
                - Consists `RAW Data`
                - Tables ()
                    - Dummy Data in these tables
            2. [Processing] (Mid-Layer)
                - Consists `Intermdiate Models` (Small Models)
            3. [Consumption] (Final-Layer)
                - Consists `Final Models`

### B.Build Scalable Data Pipelines (DBT)
---
---
- [Task]: 
    - Enhance Model -> Include "Total Revenue Generated" by customers
    - 

#### [DBT Best Practices]: 
 **Modular Approach**: `Splitting Model -> Multiple Smaller Models`
    - **Establish Relations** b/w Models (For Data Processing & Lineage Vizualization)

    - IN Real-life scenarios: Models have 1000 Lines of Code 
    - Thus, Good Practice: Modular Approach 
 
- [IMP-Concept]**Modularity**: Breaking down large models into smaller more manageable units
        -- Benefits: `Readability / Maintainability/ Reusability/ Scalability/ Testability`

[Step-1]: For "CustomerRevenue" Model: **[Build Scalable Model]**
---
[Understanding]
- When **Modularity Used** (E.g.)
    1. > Order Stg / OrderItems Stg -> Order Fact 
        - 2 Sub-Models -> 1 SemiF-Model
    2. > Customer Stg / OrderFact -> CustomerRevenue
        - 2 SemiF-Models -> 1 Main Model
- Original Query: 
    - WITH CUSTOMERREVENUE AS (
            SELECT C.CUSTOMERID, 
                CONCAT(C.FIRSTNAME, ' ', C.LASTNAME) AS CUSTOMERNAME, 
                COUNT(DISTINCT O.ORDERID) AS ORDERCOUNT,
                SUM(OI.QUANTITY * OI.UNITPRICE) AS REVENUE
            FROM L1_LANDING.CUSTOMERS C
                JOIN L1_LANDING.ORDERS O ON C.CUSTOMERID = O.CUSTOMERID
                JOIN L1_LANDING.ORDERITEMS OI ON O.ORDERID = OI.ORDERID
            GROUP BY C.CUSTOMERID, CUSTOMERNAME
            ORDER BY REVENUE DESC
        )

        SELECT CUSTOMERID, CUSTOMERNAME, ORDERCOUNT, REVENUE 
        FROM CUSTOMERREVENUE;
    
- [Modular-Approach]: Create **3 Mini Models + 1 Sub Model + 1 Final Model**
    - 3 Mini Models
        1. `customers_stg.sql`: To CONCAT "Customer Name"
        2. `orders_stg.sql`: To Define Different stages of delivery & Get `StatusDesc` (Description of Order Status) | Use CASE-WHEN-END 
        3. `orderitems_stg.sql`: Calculate TOTAL PRICE of Orders (Quantity * UnitPrice )
    - 1 Sub Model
        1. `orders_fact.sql`: Refers to 2 Mini Models (`orders_stg` & `orderitems_stg`)
            -[SYNTAX-1] Use `SELECT * FROM {{ ref('model_name')}} Aliases_Name` -> To Refer 'Other Models'
        - "Order_facts" Model = Intermediate Layer (Facilitating **Data Transformation** and **Aggregation** )
    - 1 Final Model
        1. `customerrevenue.sql`: Refers to `orders_fact` & `customers_stg` models,
            - to get "Total Revenue" w.r.t. Customers

            
[SYNTAX-2]: Use `{{ ref(model_name)}}` to Refer to Other **Models/Seeds**

[Step-2]: **Materialize All Models** -> To Enhance Performance
---
- (orders_stg, orderitems_stg, customers_stg) = `VIEW`
- (orders_fact, customerrevenue) = `TABLE`

//// [TODO] Write Differences VIEWS vs TABLES (from Video-3,10)
- **[IMP-NOTE]**: Best-Practice
    - Models with **Minor Transformations** = `VIEWS`
        - Transformations executed **at runtime** (when referenced)
    - Models with **Major Transformations** = `TABLES`
        - **Pre-executed** Transformations
- **[Interview-Question]**: How do we Strategize Materialization of Models ?
    - Evaluate Project Requirements, Performance Considerations, Storage Limitations.
    - Striking **`Right Balance b/w Performance & Storage`** is the Key



[Step-3]: **Store Models** in Schemas | **Target & Other** Schemas
---
- "Intermediate Models" (orders_stg, orderitems_stg, orders_fact, customers_stg ) -> **"Processing"** Layer
- "Final Model" (customerrevenue) -> **"Consumption"** Layer

- > Go to `dbt_project.yml"` -> Add Below Snippet -> Defines Table's Target Schemas & Materialized Forms
    - `models`:
        - `project_name`:
            - `model_name`:
                - `materialized: type`**(table/view**)
                - `schema: schema_name`
- **IMP- PROBLEM**: Overwriting `Default Target Schema Name` to `Custom Schema Name` = NOT Straightforward
- **SOLUTION**: Go to **Macros** -> Write `generate_schema_name.sql` Model's MACRO script
    - Helps Over-writting the 'Schema Name'


[NOTE]: **Don't Define** "`materialzed: view`" it is already default.

[Step-4]: Run DBT Command
---
- 2 Ways
    1. `dbt run`: Runs' all Models
    2. `dbt run --models +model_name1 +model_name2 `: Runs' Specific Model 
        - **Preciding Models Referred** in the Model : **Executed** as well
        - Multiple Specific Models can run at Once.

- Refer **logs/dbt.log** folders -> For detailed logs and debugging



[Step-5 **`(Interview-IMP)`**]: Convert Table Types (`Transient` -> `Permanent`) | Option (Mandatory for Prod.) 
---
- Tables Created = `Transient` in Snowflake (default) || OK: For Development & Testing
- In Production: `Permanent` Tables required

- > Go to "dbt_project.yml" -> Go to "models:" -> **Add at Start`+transient: false`**

- > Go to "Lineage" (in terminal) -> See Relationship b/w Models -> Click "Specific" Models -> See "Preciding" Models

### C. DBT [Seeds, Analyses, Sources]
---
---
#### 1. [DBT Seeds]
- Seeds = **Reference / Lookup Datasets - CSVs** 
    - Easily Uploaded to DWH 
    - Mostly Static data
- > Go to "Seeds" folder -> Add "salestargets.csv" file -> Add dummy data
    - [NOTE]: **Table Name** == **Seed File Name** | Should be
- [SYNTAX-1]: `dbt seed --select seed_fname` : Load CSV files to DWH
- [SYNTAX-2] Use `{{ref('seed_fname')}}` To be Used in Model || Similar to Other Models

#### 2. [DBT Analyses]
- Form **.sql** files in `analyses/` folder.
- Models/Queries = **NOT Materialized** into DWH
- Used to **Analyze/Run SQL Queries** -> Before Model Dev. in (models/)
    - Use "Run" button on Top-Right | To analyze the data
- [SYNTAX-1]: `dbt compile` - To **generate Metadata**

#### 3. [DBT Sources] 
- Initially, `TARGET_SCHEMA.TARGET_TABLE` are Directly Mentioned in "**DBT-Model**" files
- **[IMP] Makes DBT Sources Dynamic** (TARGET_SCHEMA, TARGET_TABLE) etc..
- > Go to "Models/" folder -> Create `file_name.yml` YAML file, Write Below Code
    - [SYNTAX-1]: To Make Data Sources <> Dynamic
        - sources:
            - `- name: ref_src1_name`
            -   `description: "str"`
            -   `database: DB_NAME`
            -   `schema: SCHEMA_NAME`
            - `- name: ref_src2_name`
            -   `description: "str"`
            -   `database: DB_NAME` //Any DB can be referred
            -   `schema: SCHEMA_NAME2`


- > Go to "Model_files.sql" -> Make Data Sources Dynamic 
    - [SYNTAX-2]: Use `{{ source('source_name', 'table_name')}}` Instead of **TARGET_SCHEMA.TARGET_TABLE**
        - source_name: Initial Name ('landing')
        - table_name: given name 
- Makes Changes in Configuration - Makes **workflow Scalable** (Best Practice)
- **Sources** Get added to "Lineage" Diagrams & Help with </Data Governance>

- **[Important-Note]**
1. `Multiple Schemas/Databases` can be Written `in "Source" YAML` -> Under `source:`

### D. [DBT Tests & Source Checks] 
---
---
#### 1. [DBT Tests]
---
- Function: To perform **QA/ Testing/ Sanity Checks** on Data -> Maintains **Reliability & Data Accuracy**
- [SYNTAX-1]: `dbt test` : To test/validate the data w.r.t. Logic 
- 2 Types of DBT Tests
    1. `Singular Test`:
        - Create SQL Logic w.r.t. **Single Model* -> **1 Use-Case**
        - To Create:
            - > Go to "Tests" folder -> Create 'fname.sql' file -> Write Testing Logic (1Table) ->  Run `dbt test` to Test the Data w.r.t. Logic


    2. `Generic Test`
        - [Part-1]: User-Defined Test
            - Create SQL Logic w.r.t. **Generic Usecase** -> Applicable to **Multiple Models**
            - By **Parameterizing I/Ps** using MACROS syntax
            - [SYNTAX-2]: Generic Test Syntax
                - `{% test tst_name(model, column_name) %}`
                -   `SQL generic logic`
                - `{% endtest %}`
                    - [NOTE]: Make Parameters generic using `{{}}` in SQL logic
                    - [NOTE]: tst_name == Test file name

            - Can be Built In:
                1. > Go to "Tests" -> Create folder "Generic" -> Create "fname.sql" file & write logic
                2. > Go to "Macros" -> Create "fname.sql" file & write logic
        
        - [Part-2]: Built-In Generic Tests
            - 4 Built-In generic tests
                1. `Not_Null`: Ensures **no cols.** have **N/A** 
                2. `Unique`: Ensures **each row** in a table is **Unique**
                3. `Accepted_Values`: Ensures Col_values, within **specified values**
                4. `Relationships`: Ensures **relations** b/w tables are **correct**
        - Steps:
            1. > Create Generic Test (in tests/generic/ or macros/)
            2. > Go to 'models/' -> Create 'name.yml' YAML file -> Type code to Use the Generic test
            - [SYNTAX-3]: USE "Built-In" Generic Tests 
                - `models`: 
                    - `- name: model_A`
                    -   `columns:`
                        - `- name: col_1` //generic column
                        -   `data_tests:` 
                            - `- tst_name` //user-defined
                            - `- unique`   //Built-In
                            - `- not_null` //Built-In
                        
                        - `- name: col_2`
                        -    `data_tests:`
                            - `- accepted_values:` //Built-In
                                - `values: [x, y, z]`

                            - `- relationships:` //Built-In
                                - `to: ref('model_B')`
                                - `field: key`

                -  Organizes applying **Generic tests on Models**
            3. Run `dbt test`

#### 2. [DBT Source Checks]
---
- Apply Data Checks to Sources in `source_name.yml` | Consists of DB Info. | Used to make Naming, dynamic
- 2 Popular Types
    1. Apply `Generic Tests` to Tables , when loading data 
        - Under `tables`
            - [SYNTAX-1]:
                - `- name: ref_tbl_name`
                -   `identifier: actual_tblname`
                -   `columns:`
                    -  `- name: col_name`
                    -    `data_tests:`
                        -    `- generic_tests`


    2. Apply `Freshness` Check 
        - To check if data is stale or freshely updated.
        - > Go to `models/source_name.yml` -> After `schema` ADD below as Global Var. (Applicable on all tables)
        - [SYNTAX-2]: FRESHNESS CHECK
            - `freshness:`
                - `warn_after: {count: 1, period: day}`
                - `error_after: {count: 3, period: day}`
            - `loaded_at_field: update_date_col`
        - [SYNTAX-3]: Run `dbt source freshness` : To check Freshness of the sources

#### IMP Notes
---
1. `Test Coverage(%) = (No. of Test Scenarios Executed/ Total No. of Test Scenarios) * 100`
2. **Testing Logic** is based on Business Logic
3. DBT follows **`DRY-Coding`** Principle (Don't-Repeat-Yourself)
4. `Generic Tests`
    - User-Defined Tests + Built In Tests -> To be Applied Creating a YAML
    - Multiple Tests can be Applied to 1 Column/1 Table | Easily
    - Can be Applied to [**Generic Tests =`Models + Sources`**]
5. Why Source Checks/Tests required ?
- To Detect Issues in Data in early stages of Pipeline.
    - 2 Types (Use `DBT Generic Tests` + `Source Freshness`)

### E. [DBT Auto-Documentation] 
---
---
- DBT generates, Auto-Docs. for its entire infrastructure by referring to (.yml configs, model-files, DWH etc..) in its entirety
- DBT Docs Benefits
    1. **Improves communication** among stakeholders
    2. Makes project understandable and **maintainable**
    3. **Accelerates onboarding** new team members
    4. **Self-service portal** for common queries, etc..
- DBT tightly integrates Documentation <-> Code
    - DBT Docs = Always Upto-Date

**[Ways]** to Enhance Documentation:
1. [Manual] ADD `description: desc_string` in YAML (config files)
2. [Dynamic] Create `.md` file in "models/" using `jinja doc strings`
    - Use **jinja doc strings** == **desc_string** in YAML file
    - Use when, **"Large Descriptions" / "Formtted Texts" / "Reusable Doc. Blocks"**
    - Multple doc-blocks can be added in 1 YML file
    - [SYNTAX-1] (in .md): 
        - `{% docs common_attr_name %}`
        - Description
        - `{% enddocs %}`  
    - [SYNTAX-2] (in .yml):
        - `description: {{doc('common_attr_name')}}` 
    - [SYNTAX-3]: `dbt docs generate` : Generates Doc. on the DBT Workspace
    - [SYNTAX-4]: `dbt docs serve`: To Make docs accesible to everyone
        - Makes a **POST Call** on **Airflow** -> Open a DBT_portal (w.r.t. `localhost`)
        - Referesh it: Makes a GET Call -> To get Doc info.


### F. [Jinja Language] : Template Designing Language
---
---
- 3 Main languages in DBT:
    1. SQL: **Dev.** Models & Test
    2. YAML: For **configurations**
    3. `Jinja`: To make **SQL & YAML dynamic**
        - **[Expressions]**
            - {{ref('model_name')}} & {{ref('seed_name')}}
            - {{config(materialized=type)}}
            - {{doc('doc_attr_name')}}
            - {{source('source_name', 'ref_table_name')}}
        - **[Control-Statements]**
            - {% docs doc_attr_name %} ... {% enddocs %}
            - `{% macro mcro_name(args) -%} ...{%- endmacro %}`

[Jinja] = Templating Language

#### 1. [Jinja-Building-Blocks]
1. `Control Statements`: Anything Starts-Ends w/ `{% %}`
    - Ex. (Control Statements)
        1. Variable Declaration - {% set_var_a=10 %}
        2. If, End-If statements - `{% if cond: %}...{% endif %}`
        3. For loop, End-For - `{% for i in range(var_a) %}...{% endfor %}`
    - Function: Controls the **Statement flow** | Not Printed
2. `Expressions`: Starts-Ends w/ `{{ }}` 
    - Function: Content is **Evaluated** at runtime-> **Result Printed**
3. `Text`: `SQL` Statements  
    - Function: **Executed** & Printed (in **Generated code** on DBT)
4. `Comments`: Starts-Ends w/ `{# comment #}`
    - Function: Not Printed (Just personal understanding)

#### 2. [Jinja_Use-Cases]
1. `Testing Data`/ Code
2. `Generate Dynamic SQL` (For Models - Generic Tests)
3. `Generate Dynamic YAML` configurations

#### 3. [IMP-Advantages_Of_Jinja]
- **Reduces Code** Lines 
- Enhances Code `Readability` + `Reusability` + `Scalability` + `Maintainability` + `Testability`

##### Jinja- Usecase (Example)
- [Problem-Statement]: In one of our projects , we successfully passed all dbt tests in lower envs. However, upon moving the code to prod., we encountered several data quality issues.
- [Root-Cause]: The tests in lower envs. were run on insufficient data
- [Solution]: Check "Bare Minimum Rows" for Each table
    - Generate **Dynamic SQL** Queries -> Dynamic **Generic Tests**
        - To Check for ALL tables, at once. 
- [Remedy]: **Add** this Test-Logic, to all Models, **before_hand** to santity check "No. Of Records"


#### 4. [Jinja] IMP NOTES
1. `Jinja` uses **Python Data-Types**
2. Use `table_names` given in **"Source Yaml" = "Reference Table Name"** when running a Dynamic Query, and passing the table_names
    - Else, causes an error `table not found`
3. For ALL Jinja Templates 
    - **[`file_name = template_pseudo name`]** (Should be SAME)
        - e.g. For 'customers_history.sql' -> `{% snapshot customers_history %}`

### G. [DBT Macros] 
---
---
#### 1. Overview
- DBT Macros ~ **Python Functions**
- Write **Complex Dynamic Logic** - For Multiple Models
    - Provides `Model-Reusability`
- [SYNTAX-1]: 
    - `{% macro mcro_name(arg_1, arg_2..)%}`
    -  `SQL Logic w/ {{}}` (Expressions)
    - `{% endmacro %}`
        - `Arg*` : Can set a default value (If needed) | Thus, if no I/P - still model runs.

- [STEPS]
    1. > Go to "Models" -> Create "model_to_dynamic_name.sql" that Needs to be a **Dynamic Model** -> Write logic 
    2. > Go to "Macros" -> Create `macro` w/ **`MAIN LOGIC` (Not entire SQL Logic)** -> Give "I/P Paramters" (temp, decimal)
    3. > Go to "model_to_dynamic_name.sql" -> Use Macros instead of Hard Code 

    - [SYNTAX-2]: `{{ macro_name(arg_1, arg_2..)}}`: To **REFER Macros**

[Pros-OF-MACROS]
1. **Avoid Repitative** logic writing -> Use MACRO 
    - Can Re-Use same **dynamic-Code-block** / Logic for Multiple Tables

[Problem]: Calculate Profit from 10 Tables & generate 10 Tables
[Solution]:
- **Traditional Approach**: Create 'Model' (for each) -> Modify Config. (for each) 
    - Result:  **No Scalability - No Flexibility** (If, Logic Changes)
- **Macros Approach**: Create `Macro` (Dyanmic-Logic) -> Works with Multiple Models 
    - Result: **Scalability + Flexibility** 
        - Coz. No need to build 10 models // Modification at Ease

#### IMP-NOTES (Macros) | Interview
1. MAIN LOGIC `(Part-Code)` OR `ENTIRE SQL LOGIC`  -> Can be dev. as `Macro` 
2. `1 DBT Model` -> `1 DB Object(table/view)`
    -  **Bad Practice**, to Create *Multiple Source/Target* Tables **using 1 File**
3. Can Add **Multiple Macro Code-Blocks** in **1 File**
4. *Macro/Model* in `DBT don't refer` to **ALIASED Names** , When using *Jinja* Templates

### H. [DBT Packages] 
---
---
- DBT Packages = `Pre-Built DBT Projects`
    - Including DBT Models-Macros-Allfunctionalities to Address **Common Use-Cases**
    - From `hub.getdbt.com` -> `Import DBT Packages` -> Customize & Use there functions/models/etc..

#### 1. [Add DBT Packages - To your Project]
---
- 2 Ways : 
    1. Configure: **Packages-Version**
    2. Configure: **Git-Revision**
        - > Go to "f_dbt_proj" -> Create 'packages.yml' -> Add Below Syntax
        - [SYNTAX-1]: 
            - packages:
                - `- package: path/package_name`
                -   `version: version_no`
                - `- git: "https//:link_to_git_repo"`
                -   `revision: tag_value`
        - [SYNTAX-2]: ADD Packages to Project Env.
            - `dbt deps` :Loads DBT Dependencies (Packages)

#### 2. [Use DBT Packages]
---
- Go to `hub.getdbt.com` -> Select Functionality/Model to use -> Go to Git(of that model) -> Copy ANY `Usage Templates` snippet 
    1. > //FOR-Models// Paste in **models/model_name.sql** (To use) -> **Customize** the Params, accordingly. -> Run `dbt run --select model_name`
    2. > //FOR-Tests// Paste in **src_config.yml** (To use) -> Under `tests:` for specific table/source-> **Customize** the Params, accordingly. -> Run `dbt test`

### I. [DBT Materialization] 
---
---
- `Materialization`: Way to incorporate **DBT Models/Seeds/Snapshots into DWH** using `dbt run`
- 5 Types of Materializations.
    1. `[Table]`:  
        - Create **New Table Object** in DWH - Everytime DBT Runs **(Drops if Exists)**
            - `Extracts Complete Data` from Source_Table/ Ref_models -> **Dumps** to Target_table
        - Storage: Permanently on DWH Storage
        - Performance: Faster
        - Usecase: `Small Tables` (That can be Updated everyday)

    2. `[View]`:
        - Creates **New View Object** in DWH **(Drops if Exists)**
            - `Executes & Loads Data @runtime` when Referred by **Succeding Models** 
                - User Queries Succeding Models / BI Referring to the logic
            - Serve as **`Definitions Layer`** on top of **Specific tables**
        - Storage: No Data Storage
        - Usecase: Models w/ `small transformations`

    3. `[Ephemeral]`: 
        - No Objects created in DWH
            - DBT **incorporates Code** from 'Ephemeral' model into **Dependent models** AS `CTEs`(Common Table Expressions)
                - Dependent Models = **Can Get Materialized** (Table/View)  
    4. `[Incremental]`: 
        - **Inserts Data** to Existing Tables (**Every DBT run**) -> **Incrementally**
        - Usecase: `Large Tables` (Billion records)
        -  [SYNTAX-1]: 3 Stages 
            - `{{config (materialized='incremental', unique_key='key')}}`  
            - `SQL Logic`
            - `{% if is_incremental() %}`
            - `WHERE (DELTA APPROACH)`
            - `{% endif %}`

        - [Understanding - Incremental Materialization]
            1. `is_incremental()` = **TRUE, when** ALL Conds. met
                 - [Conditions]:
                    1. Destination_Table = Already_Exists
                    2. **DBT NOT** running in **`Full refresh mode`**
                        - [SYNTAX-2]: `dbt run --full-refresh`
                    3. Model Configured set to 'incremental'
            2. `unique_key`: Used to Handle **UPDATE** statements.

            2. **DELTA APPROACHES** : Multiple Approaches to Find </Incrementing Point/> | Some common 
                - Finds Delta Records from the Source (**When Last DBT Run** Happened -> **WHERE to Increment Data From**)
                    1. `WHERE src_col_name >= (SELECT MAX(trg_col_name) FROM {{this}})`
                        - `{{this}}`: Internal DBT var. (result: **target_table**)
                        - Logic: Extracting Records added **after Max. Update time** in **Target_Table**
                    2. `WHERE src_col_name > DATEADD(HOUR, -6, (SELECT MAX(trg_column_name) FROM {{this}} ))`
                        - Logic: Extracting Records added **after Max. 6 Hours OFFSET** in **Target_Table** 
                            - Use when *Delay = Expected*
                    3. `WHERE src_col_name > DATEADD(DAY, -7, current_data)`
                        - Logic: Extracting **Prev. 1-Week** records 
                            - Use: To *aggregate Prev-week* data
        - [Observations]
            1. When Incremental Run Occurs -> `INSERT` statements -> *Added to Model* 
            2. If *Source-Data `(Gets.Updated)`* | **Post Insert**  
                - DBT *Checks if* **unique_key** *Exists* in "Target Table"
                    - Yes, **UPDATE**'s  the Records
                    - No, **INSERT**'s the Records
                - Result = `MERGE` Statement is Executed -> *Added to Model* 


    5. `[Snapshots]`: 
        - Function: To **Capture `Historical Data Changes` over time**
            - Caters to `{SCD Type-2}` in DBT | (New-ROW-Added : History Preserved)
            - [Strategies]:
                1. **Timestamp Strategy** : Table `w/ Time` col.
                    - [SYNTAX-0A]: Use
                        - `strategy = timestamp`
                        - `updated_at = 'DT_colname'`
                            - Created 'VALID_FROM, VALID_TO, DBT_UPDATED_AT' cols. in "New-Table"
                            - Analyze Historical data on "Date" columns
                     
                2. **Check Strategy** : Table `w/o Time` Col.
                    - [SYNTAX-0B]: Use
                        - `strategy = check`
                        - `updated_at = ['cols_to_check']`
                            - `cols_to_check`: `all` (Possible)
                                - BUT Consider using **Surrogate Key = List of All Columns (To Check)**
                            - Created 'VALID_FROM, VALID_TO, DBT_UPDATED_AT' cols. in "New-Table"
                            - Analyze Historical data on "Date" columns

            - [SYNTAX-1]:
                - `{% snapshot snap_fname %}`
                - `{{` 
                    - `config(`
                        -    `target_database='name',`
                        -    `target_schema='name',`
                        -    `unique_key='key_name',`
                        -    `strategy='timestamp',`  OR `strategy='check'`
                        -    `timestamp='DT_colname',` OR `check_cols=[cols_to_check]`
                        -    `)`
                        - `invalidate_hard_deletes=True/False`
                - `}}`
                - `SQL Logic` (SELECT * FROM )
                - `{% endsnapshot %}`
            - [Understanding]:
                - Using Above Config -> Creates Snapshot Table (initially) 
                - `DBT_VALID_FROM` & `DBT_VALID_TO`: Change (IF Records Change) for `'strategy='timestamp'`
                - `invalidate_hard_deletes`: 
                    - In 'src_tbl' Records (gets deleted) -> `DBT Ignores Changes` in 'target_tbl' | When **'invalidate_hard_deletes' = TRUE** (Default)
                    - In 'src_tbl' Records (gets deleted) -> `DBT Updates VALID_TO` in 'target_tbl' -> To **Latest `dbt snapshot` run** | When **'invalidate_hard_deletes' = FALSE** 
            
            - [SYNTAX-2]: `dbt snapshot --select snap_name`: To Run Snapshot Files 


- [Problem-Statement]: Company Wants to avoid flooding DWH with unnecessary objects. However we want to define those models within `dbt/` context for Modularity & Reusability
- [Solution]: Convert `Views` -> `Ephemerals`
    - No Logic issues, and No added materialization

### J. [Production] 
---
---
1. [Job-Schedulers]: **Airflow/ Dagster**   
    - Use: Schedules DBT Models/Jobs -> Automates the Runs
    - Pro: No Manual using `dbt commands`
2. [CI-Version_Controllers]: **Github /Gitlab/Bitbucket**
    - Use: Maintain Multiple Code versions - Merge Multiple Code Versions
    - > CI: Workflow: Code Changes -> Deploy to Sub-branch -> `git pull` request -> Merge to Main-Branch (w/ approvals)
3. [CD-DevOps_Tools]: **Github-Actions/ Azure DevOps/ Jenkins**
- > CD: Automated Code Deployement (Main Branch) -> Pre-Prod envs. (To test) -> Prod. Server (Production)


### DE- Concept
---
#### A. SCD(Slowly Changing Dimensions)
- > Certain Attributes of Records -> Change Overtime -> **OLTP sources** (*Don't Maintain History*) 
    - E.g. : Cx_mobile, Cx_city, Cx_email etc.. 
- > Analytical Systems (Have to Maintain History) -> to **Analyze Historical Data**

##### [Types of SCDs]
-  Many Types of SCDs | Common Ones are:
    1. `SCD Type 1` : [Overwrites-Changes]
        - History **NOT Preserved** 
    2. `SCD Type 2` : [New-ROW-Added]
        - History Preserved  (as a new row)
    3. `SCD Type 3` : [New-COL-Added]
        - History Preserved (as a new row)


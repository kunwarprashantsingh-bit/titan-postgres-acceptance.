-- Global Cement Sustainability Intelligence
-- PostgreSQL Implementation v1.0 — PG-04 Observation & Accounting Layer
-- Requires PG-01 through PG-03.
BEGIN;

CREATE TABLE titan_ref.value_state (
    value_state_code text PRIMARY KEY,
    permits_numeric boolean NOT NULL,
    requires_zero boolean NOT NULL DEFAULT false,
    definition text NOT NULL
);

CREATE TABLE titan_ref.data_class (
    data_class_code char(1) PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.quantity_kind (
    quantity_kind_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.methodology_family (
    methodology_family_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.methodology_status (
    methodology_status_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.inventory_type (
    inventory_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.inventory_version_status (
    inventory_version_status_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.inventory_component_type (
    inventory_component_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.gross_net_role (
    gross_net_role_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.measurement_method_type (
    measurement_method_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.moisture_basis (
    moisture_basis_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.material_flow_status (
    material_flow_status_code text PRIMARY KEY,
    actual_flow_flag boolean NOT NULL,
    definition text NOT NULL
);

CREATE TABLE titan_ref.product_version_status (
    product_version_status_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.epd_type (
    epd_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.comparability_result (
    comparability_result_code text PRIMARY KEY,
    definition text NOT NULL
);

INSERT INTO titan_ref.value_state VALUES
('VALUE',true,false,'A disclosed/measured/derived/modelled/proxy value exists'),
('ZERO',true,true,'The evidenced value is exactly zero'),
('UNKNOWN',false,false,'Value genuinely unknown'),
('NOT_DISCLOSED',false,false,'Known to exist but not disclosed'),
('NOT_PUBLICLY_VERIFIED',false,false,'No sufficient public verification recovered'),
('NOT_APPLICABLE',false,false,'Metric does not apply to this boundary/entity/period'),
('NOT_YET_DUE',false,false,'Obligation/metric not yet due for the period'),
('WITHHELD_CONFIDENTIAL',false,false,'Value withheld/confidential'),
('CONFLICT_UNRESOLVED',false,false,'Material evidence conflict blocks one selected value'),
('PROVISIONAL',true,false,'Provisional value subject to confirmation');

INSERT INTO titan_ref.data_class VALUES
('R','Reported — directly stated by authoritative/source evidence'),
('D','Derived — calculated from evidenced inputs'),
('M','Modelled — estimated using an explicit model/assumptions'),
('P','Proxy — borrowed from an explicitly identified comparable source');

INSERT INTO titan_ref.quantity_kind VALUES
('ABSOLUTE','Absolute quantity; no denominator'),
('INTENSITY','Quantity per explicit denominator definition'),
('RATIO','Dimensionless ratio/share or explicitly defined ratio metric'),
('CONCENTRATION','Concentration under an explicit measurement basis'),
('LIMIT','Legal/permit/technical limit rather than observed performance'),
('INDEX','Index/score with an explicit method'),
('OTHER','Other explicitly defined quantity kind');

INSERT INTO titan_ref.methodology_family VALUES
('CORPORATE_GHG','Corporate GHG inventory/accounting'),
('CEMENT_CO2_ENERGY','Cement/clinker CO2 and energy accounting'),
('PRODUCT_LCA','Product LCA/EPD accounting'),
('REGULATORY','Regulatory/compliance methodology'),
('MATERIAL_ACCOUNTING','Material/provenance accounting'),
('ENERGY_ACCOUNTING','Energy/fuel accounting'),
('OTHER','Other explicit methodology family');

INSERT INTO titan_ref.methodology_status VALUES
('CURRENT','Current production methodology'),
('VALID','Valid for a defined period'),
('EXPIRED','No longer valid for new periods'),
('FUTURE_EFFECTIVE','Published but not yet effective'),
('DRAFT','Draft method'),
('CONSULTATION','Consultation/proposal'),
('SUPERSEDED','Superseded methodology version');

INSERT INTO titan_ref.inventory_type VALUES
('CORPORATE','Corporate/group inventory'),
('PLANT','Plant/site inventory'),
('PRODUCT','Product footprint/inventory'),
('REGULATORY','Regulatory inventory/compliance calculation'),
('PROJECT','Project inventory'),
('OTHER','Other explicit inventory type');

INSERT INTO titan_ref.inventory_version_status VALUES
('ORIGINAL','Originally reported/calculated series'),
('RESTATED','Historical value restated to a revised perimeter/methodology'),
('REVISED','Revised/corrected inventory version'),
('SUPERSEDED','Historical inventory no longer current but retained');

INSERT INTO titan_ref.inventory_component_type VALUES
('PROCESS_CO2','Process/mineral calcination CO2'),
('FOSSIL_FUEL_CO2','Fossil fuel combustion CO2'),
('BIOGENIC_CO2','Biogenic CO2 reported separately'),
('CH4','Methane'),
('N2O','Nitrous oxide'),
('SCOPE1_OTHER','Other Scope 1 GHG component'),
('SCOPE2_LB','Scope 2 location-based emissions'),
('SCOPE2_MB','Scope 2 market-based emissions'),
('SCOPE3_CATEGORY','Scope 3 category component'),
('REMOVAL','Removal meeting applicable methodology conditions'),
('OFFSET','Offset/carbon-credit adjustment'),
('AVOIDED','Avoided-emissions memo item'),
('OTHER','Other inventory component');

INSERT INTO titan_ref.gross_net_role VALUES
('GROSS','Gross inventory component/result'),
('NET','Net/claim-adjusted result'),
('MEMO','Memo item not included in gross total'),
('REMOVAL','Removal component'),
('OFFSET','Offset/credit component'),
('AVOIDED','Avoided-emissions item outside gross inventory');

INSERT INTO titan_ref.measurement_method_type VALUES
('CEMS','Continuous emissions monitoring system'),
('STACK_TEST','Periodic stack/emissions test'),
('MASS_BALANCE','Mass-balance calculation'),
('EMISSION_FACTOR','Activity data × emission factor'),
('LABORATORY','Laboratory analytical result'),
('SUPPLIER_EPD','Supplier EPD/verified declaration'),
('METER','Metered physical quantity'),
('MODEL','Modelled/substitute method'),
('OTHER','Other explicit method');

INSERT INTO titan_ref.moisture_basis VALUES
('DRY','Dry basis'),
('WET','Wet basis'),
('NOT_APPLICABLE','Moisture basis not applicable'),
('UNKNOWN','Moisture basis unknown');

INSERT INTO titan_ref.material_flow_status VALUES
('TENDER',false,'Tender/expected quantity; not realized flow'),
('CONTRACTED',false,'Contracted quantity; not necessarily realized'),
('DELIVERED',true,'Delivered physical material'),
('CONSUMED',true,'Consumed physical material'),
('DISPATCHED',true,'Dispatched physical material'),
('MEASURED',true,'Measured physical flow'),
('ESTIMATED_ACTUAL',true,'Estimated realized flow with explicit method');

INSERT INTO titan_ref.product_version_status VALUES
('CURRENT','Current product/formulation version'),
('HISTORICAL','Historical product/formulation version'),
('PROVISIONAL','Provisional/pre-launch formulation'),
('SUPERSEDED','Superseded product version');

INSERT INTO titan_ref.epd_type VALUES
('PLANT_SPECIFIC','Plant-specific declaration'),
('MULTI_PRODUCT_AVERAGE','Average across multiple products'),
('MULTI_SITE_AVERAGE','Average across multiple manufacturing sites'),
('SECTOR_AVERAGE','Sector/industry average declaration');

INSERT INTO titan_ref.comparability_result VALUES
('COMPARABLE','Records are like-for-like under the applicable rule'),
('CONDITIONALLY_COMPARABLE','Comparison requires an approved normalization/alignment and disclosure'),
('NOT_COMPARABLE','Records are not like-for-like for the proposed analytical use');

CREATE TABLE titan_core.unit_master (
    unit_code text PRIMARY KEY,
    symbol text NOT NULL,
    dimension_code text NOT NULL,
    base_unit_symbol text NULL,
    factor_to_base numeric NULL CHECK (factor_to_base IS NULL OR factor_to_base > 0),
    definition text NOT NULL,
    CONSTRAINT ck_unit_symbol_nonblank CHECK (btrim(symbol) <> ''),
    CONSTRAINT ck_unit_dimension_nonblank CHECK (btrim(dimension_code) <> '')
);

INSERT INTO titan_core.unit_master VALUES
('T_CO2E','tCO2e','MASS_CO2E','kgCO2e',1000,'Metric tonnes CO2 equivalent'),
('KG_CO2E','kgCO2e','MASS_CO2E','kgCO2e',1,'Kilograms CO2 equivalent'),
('T_CO2','tCO2','MASS_CO2','kgCO2',1000,'Metric tonnes carbon dioxide'),
('TONNE','t','MASS','kg',1000,'Metric tonne material/product'),
('KG','kg','MASS','kg',1,'Kilogram'),
('MWH','MWh','ENERGY','GJ',3.6,'Megawatt-hour'),
('GJ','GJ','ENERGY','GJ',1,'Gigajoule'),
('M3','m3','VOLUME','m3',1,'Cubic metre'),
('MG_NM3','mg/Nm3','CONCENTRATION',NULL,NULL,'Milligrams per normal cubic metre; conversion depends on reference conditions'),
('PERCENT','%','RATIO','fraction',0.01,'Percent'),
('FRACTION','1','RATIO','fraction',1,'Dimensionless fraction'),
('EUR','EUR','CURRENCY',NULL,NULL,'Euro; FX conversion requires dated reference, not a fixed factor'),
('INR','INR','CURRENCY',NULL,NULL,'Indian rupee; FX conversion requires dated reference, not a fixed factor'),
('CNY','CNY','CURRENCY',NULL,NULL,'Chinese yuan; FX conversion requires dated reference, not a fixed factor');

CREATE TABLE titan_core.denominator_definition (
    denominator_id text PRIMARY KEY,
    denominator_name text NOT NULL,
    denominator_unit_code text NOT NULL REFERENCES titan_core.unit_master(unit_code),
    methodology_family_code text NULL REFERENCES titan_ref.methodology_family(methodology_family_code),
    boundary_definition text NOT NULL,
    source_id text NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    valid_from date NULL,
    valid_to date NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_denominator_id CHECK (denominator_id ~ '^DEN-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_denominator_name CHECK (btrim(denominator_name) <> ''),
    CONSTRAINT ck_denominator_boundary CHECK (btrim(boundary_definition) <> ''),
    CONSTRAINT ck_denominator_dates CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to >= valid_from)
);

INSERT INTO titan_core.denominator_definition
(denominator_id,denominator_name,denominator_unit_code,methodology_family_code,boundary_definition)
VALUES
('DEN-CLINKER','Clinker','TONNE','CEMENT_CO2_ENERGY','Kiln/plant clinker output'),
('DEN-CEMENT','Cement','TONNE','CEMENT_CO2_ENERGY','Cement production'),
('DEN-CEMENTITIOUS','Cementitious product','TONNE','CEMENT_CO2_ENERGY','Method-defined cementitious production'),
('DEN-CEM-EQ','Cement equivalent','TONNE','CEMENT_CO2_ENERGY','Protocol-defined equivalent output'),
('DEN-CCTS-EQPROD','Equivalent product','TONNE','REGULATORY','India CCTS scheme-defined equivalent product'),
('DEN-PRODUCT-MASS','Declared product mass','TONNE','PRODUCT_LCA','Declared product-mass unit'),
('DEN-CONCRETE-VOL','Concrete volume','M3','PRODUCT_LCA','Declared/functional concrete volume');

CREATE TABLE titan_core.methodology_master (
    methodology_id text PRIMARY KEY,
    methodology_family_code text NOT NULL REFERENCES titan_ref.methodology_family(methodology_family_code),
    methodology_name text NOT NULL,
    authority_name text NOT NULL,
    methodology_notes text NULL,
    CONSTRAINT ck_methodology_id CHECK (methodology_id ~ '^METH-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_methodology_name CHECK (btrim(methodology_name) <> ''),
    CONSTRAINT ck_methodology_authority CHECK (btrim(authority_name) <> '')
);

CREATE TABLE titan_core.methodology_version (
    methodology_version_id text PRIMARY KEY,
    methodology_id text NOT NULL REFERENCES titan_core.methodology_master(methodology_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    version_label text NOT NULL,
    methodology_status_code text NOT NULL REFERENCES titan_ref.methodology_status(methodology_status_code),
    valid_from date NULL,
    valid_to date NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    superseded_at timestamptz NULL,
    CONSTRAINT ck_methodology_version_id CHECK (methodology_version_id ~ '^METHV-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_methodology_version_label CHECK (btrim(version_label) <> ''),
    CONSTRAINT ck_methodology_version_dates CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to >= valid_from)
);

CREATE TABLE titan_core.measurement_method (
    measurement_method_id text PRIMARY KEY,
    measurement_method_type_code text NOT NULL REFERENCES titan_ref.measurement_method_type(measurement_method_type_code),
    methodology_version_id text NULL REFERENCES titan_core.methodology_version(methodology_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    method_name text NOT NULL,
    method_notes text NULL,
    CONSTRAINT ck_measurement_method_id CHECK (measurement_method_id ~ '^MEAS-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_measurement_method_name CHECK (btrim(method_name) <> '')
);

CREATE TABLE titan_core.measurement_basis (
    measurement_basis_id text PRIMARY KEY,
    reference_oxygen_pct numeric(7,4) NULL CHECK (reference_oxygen_pct IS NULL OR reference_oxygen_pct BETWEEN 0 AND 100),
    moisture_basis_code text NOT NULL REFERENCES titan_ref.moisture_basis(moisture_basis_code),
    temperature_c numeric NULL,
    pressure_kpa numeric NULL CHECK (pressure_kpa IS NULL OR pressure_kpa > 0),
    coverage_pct numeric(7,4) NULL CHECK (coverage_pct IS NULL OR coverage_pct BETWEEN 0 AND 100),
    substitution_flag boolean NOT NULL DEFAULT false,
    basis_notes text NULL,
    CONSTRAINT ck_measurement_basis_id CHECK (measurement_basis_id ~ '^BASIS-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.observation (
    observation_id text PRIMARY KEY
        REFERENCES titan_core.entity_registry(entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    subject_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    metric_code text NOT NULL,
    quantity_kind_code text NOT NULL REFERENCES titan_ref.quantity_kind(quantity_kind_code),
    value_state_code text NOT NULL REFERENCES titan_ref.value_state(value_state_code),
    data_class_code char(1) NULL REFERENCES titan_ref.data_class(data_class_code),
    numeric_value numeric NULL,
    text_value text NULL,
    unit_code text NULL REFERENCES titan_core.unit_master(unit_code),
    denominator_id text NULL REFERENCES titan_core.denominator_definition(denominator_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    boundary_version_id bigint NULL REFERENCES titan_core.boundary_version(boundary_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    methodology_version_id text NULL REFERENCES titan_core.methodology_version(methodology_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    measurement_method_id text NULL REFERENCES titan_core.measurement_method(measurement_method_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    measurement_basis_id text NULL REFERENCES titan_core.measurement_basis(measurement_basis_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    period_start date NOT NULL,
    period_end date NOT NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    superseded_at timestamptz NULL,
    supersedes_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
    observation_notes text NULL,
    CONSTRAINT ck_observation_metric CHECK (btrim(metric_code) <> ''),
    CONSTRAINT ck_observation_period CHECK (period_end >= period_start),
    CONSTRAINT ck_observation_not_self_supersede CHECK (supersedes_observation_id IS NULL OR supersedes_observation_id <> observation_id),
    CONSTRAINT ck_observation_state_payload CHECK (
        (value_state_code IN ('VALUE','PROVISIONAL') AND (numeric_value IS NOT NULL OR text_value IS NOT NULL))
        OR
        (value_state_code='ZERO' AND numeric_value=0 AND text_value IS NULL)
        OR
        (value_state_code NOT IN ('VALUE','PROVISIONAL','ZERO') AND numeric_value IS NULL AND text_value IS NULL)
    ),
    CONSTRAINT ck_observation_data_class CHECK (
        (value_state_code IN ('VALUE','ZERO','PROVISIONAL') AND data_class_code IS NOT NULL)
        OR
        (value_state_code NOT IN ('VALUE','ZERO','PROVISIONAL') AND data_class_code IS NULL)
    ),
    CONSTRAINT ck_observation_unit CHECK (
        numeric_value IS NULL OR unit_code IS NOT NULL
    ),
    CONSTRAINT ck_observation_denominator CHECK (
        (quantity_kind_code='INTENSITY' AND denominator_id IS NOT NULL)
        OR
        (quantity_kind_code<>'INTENSITY' AND denominator_id IS NULL)
    )
);

CREATE TRIGGER trg_observation_type
BEFORE INSERT OR UPDATE ON titan_core.observation
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_child_entity_type('observation_id','OBSERVATION');

CREATE TABLE titan_core.observation_evidence_link (
    observation_evidence_link_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    extraction_id text NOT NULL REFERENCES titan_core.extraction_record(extraction_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    support_type_code text NOT NULL REFERENCES titan_ref.support_type(support_type_code),
    evidence_notes text NULL,
    CONSTRAINT uq_observation_evidence UNIQUE(observation_id,extraction_id)
);

CREATE TABLE titan_core.observation_derivation (
    observation_id text PRIMARY KEY REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    formula_text text NOT NULL,
    calculation_notes text NULL,
    CONSTRAINT ck_derivation_formula CHECK (btrim(formula_text) <> '')
);

CREATE TABLE titan_core.observation_derivation_input (
    observation_id text NOT NULL REFERENCES titan_core.observation_derivation(observation_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    input_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    input_role text NOT NULL,
    PRIMARY KEY(observation_id,input_observation_id,input_role),
    CONSTRAINT ck_derivation_not_self CHECK (observation_id <> input_observation_id),
    CONSTRAINT ck_derivation_input_role CHECK (btrim(input_role) <> '')
);

CREATE TABLE titan_core.observation_model_provenance (
    observation_id text PRIMARY KEY REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    model_ref text NOT NULL,
    model_version_ref text NOT NULL,
    assumption_set_ref text NOT NULL,
    uncertainty_text text NULL,
    CONSTRAINT ck_model_ref CHECK (btrim(model_ref) <> ''),
    CONSTRAINT ck_model_version_ref CHECK (btrim(model_version_ref) <> ''),
    CONSTRAINT ck_assumption_ref CHECK (btrim(assumption_set_ref) <> '')
);

CREATE TABLE titan_core.observation_proxy_provenance (
    observation_id text PRIMARY KEY REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    proxy_source_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    proxy_rationale text NOT NULL,
    uncertainty_text text NULL,
    CONSTRAINT ck_proxy_not_self CHECK (observation_id <> proxy_source_observation_id),
    CONSTRAINT ck_proxy_rationale CHECK (btrim(proxy_rationale) <> '')
);

CREATE OR REPLACE FUNCTION titan_core.validate_observation_provenance()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    obs_id text;
    cls char(1);
    state text;
    n integer;
BEGIN
    IF TG_OP='DELETE' THEN
        obs_id := OLD.observation_id;
    ELSE
        obs_id := NEW.observation_id;
    END IF;

    SELECT data_class_code, value_state_code
      INTO cls, state
      FROM titan_core.observation
     WHERE observation_id=obs_id;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    IF state NOT IN ('VALUE','ZERO','PROVISIONAL') THEN
        RETURN NULL;
    END IF;

    IF cls='R' THEN
        SELECT count(*) INTO n
        FROM titan_core.observation_evidence_link
        WHERE observation_id=obs_id AND support_type_code IN ('SUPPORTS','QUALIFIES');
        IF n < 1 THEN
            RAISE EXCEPTION 'Reported observation % requires supporting extraction evidence', obs_id;
        END IF;
    ELSIF cls='D' THEN
        SELECT count(*) INTO n FROM titan_core.observation_derivation WHERE observation_id=obs_id;
        IF n <> 1 THEN RAISE EXCEPTION 'Derived observation % requires one derivation record', obs_id; END IF;
        SELECT count(*) INTO n FROM titan_core.observation_derivation_input WHERE observation_id=obs_id;
        IF n < 1 THEN RAISE EXCEPTION 'Derived observation % requires at least one input observation', obs_id; END IF;
    ELSIF cls='M' THEN
        SELECT count(*) INTO n FROM titan_core.observation_model_provenance WHERE observation_id=obs_id;
        IF n <> 1 THEN RAISE EXCEPTION 'Modelled observation % requires model provenance', obs_id; END IF;
    ELSIF cls='P' THEN
        SELECT count(*) INTO n FROM titan_core.observation_proxy_provenance WHERE observation_id=obs_id;
        IF n <> 1 THEN RAISE EXCEPTION 'Proxy observation % requires proxy provenance', obs_id; END IF;
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER ct_observation_provenance
AFTER INSERT OR UPDATE ON titan_core.observation
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_observation_provenance();

CREATE CONSTRAINT TRIGGER ct_observation_evidence_provenance
AFTER INSERT OR UPDATE OR DELETE ON titan_core.observation_evidence_link
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_observation_provenance();

CREATE CONSTRAINT TRIGGER ct_observation_derivation_provenance
AFTER INSERT OR UPDATE OR DELETE ON titan_core.observation_derivation
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_observation_provenance();

CREATE CONSTRAINT TRIGGER ct_observation_derivation_input_provenance
AFTER INSERT OR UPDATE OR DELETE ON titan_core.observation_derivation_input
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_observation_provenance();

CREATE CONSTRAINT TRIGGER ct_observation_model_provenance
AFTER INSERT OR UPDATE OR DELETE ON titan_core.observation_model_provenance
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_observation_provenance();

CREATE CONSTRAINT TRIGGER ct_observation_proxy_provenance
AFTER INSERT OR UPDATE OR DELETE ON titan_core.observation_proxy_provenance
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_observation_provenance();

CREATE TABLE titan_core.data_quality_record (
    data_quality_id text PRIMARY KEY,
    observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    primary_data_share numeric(7,4) NULL CHECK (primary_data_share IS NULL OR primary_data_share BETWEEN 0 AND 100),
    reference_year integer NULL CHECK (reference_year IS NULL OR reference_year BETWEEN 1900 AND 2200),
    uncertainty_text text NULL,
    completeness_text text NULL,
    quality_notes text NULL,
    CONSTRAINT ck_data_quality_id CHECK (data_quality_id ~ '^DQ-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.inventory_master (
    inventory_id text PRIMARY KEY,
    boundary_version_id bigint NOT NULL REFERENCES titan_core.boundary_version(boundary_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    methodology_version_id text NOT NULL REFERENCES titan_core.methodology_version(methodology_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    period_start date NOT NULL,
    period_end date NOT NULL,
    inventory_type_code text NOT NULL REFERENCES titan_ref.inventory_type(inventory_type_code),
    inventory_version_status_code text NOT NULL REFERENCES titan_ref.inventory_version_status(inventory_version_status_code),
    supersedes_inventory_id text NULL REFERENCES titan_core.inventory_master(inventory_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    restatement_reason text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_inventory_id CHECK (inventory_id ~ '^INV-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_inventory_period CHECK (period_end >= period_start),
    CONSTRAINT ck_inventory_not_self CHECK (supersedes_inventory_id IS NULL OR supersedes_inventory_id <> inventory_id),
    CONSTRAINT ck_inventory_restatement_reason CHECK (
        inventory_version_status_code NOT IN ('RESTATED','REVISED')
        OR (restatement_reason IS NOT NULL AND btrim(restatement_reason) <> '')
    )
);

CREATE TABLE titan_core.inventory_component (
    inventory_component_id text PRIMARY KEY,
    inventory_id text NOT NULL REFERENCES titan_core.inventory_master(inventory_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    observation_id text NOT NULL UNIQUE REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    inventory_component_type_code text NOT NULL REFERENCES titan_ref.inventory_component_type(inventory_component_type_code),
    scope_or_category text NULL,
    gross_net_role_code text NOT NULL REFERENCES titan_ref.gross_net_role(gross_net_role_code),
    gas_code text NULL,
    component_notes text NULL,
    CONSTRAINT ck_inventory_component_id CHECK (inventory_component_id ~ '^INVC-[A-Za-z0-9][A-Za-z0-9._-]*$')
);


CREATE OR REPLACE FUNCTION titan_core.validate_inventory_component_context()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    inv_boundary bigint;
    inv_method text;
    inv_start date;
    inv_end date;
    obs_boundary bigint;
    obs_method text;
    obs_start date;
    obs_end date;
BEGIN
    SELECT boundary_version_id, methodology_version_id, period_start, period_end
      INTO inv_boundary, inv_method, inv_start, inv_end
      FROM titan_core.inventory_master
     WHERE inventory_id=NEW.inventory_id;

    SELECT boundary_version_id, methodology_version_id, period_start, period_end
      INTO obs_boundary, obs_method, obs_start, obs_end
      FROM titan_core.observation
     WHERE observation_id=NEW.observation_id;

    IF obs_boundary IS DISTINCT FROM inv_boundary THEN
        RAISE EXCEPTION 'Inventory component observation % boundary % does not match inventory % boundary %',
            NEW.observation_id, obs_boundary, NEW.inventory_id, inv_boundary;
    END IF;
    IF obs_method IS DISTINCT FROM inv_method THEN
        RAISE EXCEPTION 'Inventory component observation % methodology % does not match inventory % methodology %',
            NEW.observation_id, obs_method, NEW.inventory_id, inv_method;
    END IF;
    IF obs_start IS DISTINCT FROM inv_start OR obs_end IS DISTINCT FROM inv_end THEN
        RAISE EXCEPTION 'Inventory component observation % period does not match inventory % period',
            NEW.observation_id, NEW.inventory_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_inventory_component_context
BEFORE INSERT OR UPDATE ON titan_core.inventory_component
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_inventory_component_context();

CREATE TABLE titan_core.material_master (
    material_id text PRIMARY KEY,
    material_name text NOT NULL,
    material_class text NOT NULL,
    material_notes text NULL,
    CONSTRAINT ck_material_id CHECK (material_id ~ '^MAT-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_material_name CHECK (btrim(material_name) <> ''),
    CONSTRAINT ck_material_class CHECK (btrim(material_class) <> '')
);

CREATE TABLE titan_core.material_flow (
    material_flow_id text PRIMARY KEY,
    material_id text NOT NULL REFERENCES titan_core.material_master(material_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    origin_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    destination_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    quantity_observation_id text NOT NULL UNIQUE REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    material_flow_status_code text NOT NULL REFERENCES titan_ref.material_flow_status(material_flow_status_code),
    cross_border_flag boolean NOT NULL DEFAULT false,
    shipment_ref text NULL,
    flow_notes text NULL,
    CONSTRAINT ck_material_flow_id CHECK (material_flow_id ~ '^FLOW-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_material_flow_not_self CHECK (origin_entity_id <> destination_entity_id)
);

CREATE TABLE titan_core.product_master (
    product_id text PRIMARY KEY REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    product_name text NOT NULL,
    product_category text NOT NULL,
    product_notes text NULL,
    CONSTRAINT ck_product_name CHECK (btrim(product_name) <> ''),
    CONSTRAINT ck_product_category CHECK (btrim(product_category) <> '')
);

CREATE TRIGGER trg_product_master_type
BEFORE INSERT OR UPDATE ON titan_core.product_master
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_child_entity_type('product_id','PRODUCT');

CREATE TABLE titan_core.product_version (
    product_version_id text PRIMARY KEY,
    product_id text NOT NULL REFERENCES titan_core.product_master(product_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    version_label text NOT NULL,
    product_version_status_code text NOT NULL REFERENCES titan_ref.product_version_status(product_version_status_code),
    valid_from date NOT NULL,
    valid_to date NULL,
    standard_ref text NULL,
    formulation_notes text NULL,
    CONSTRAINT ck_product_version_id CHECK (product_version_id ~ '^PRODV-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_product_version_label CHECK (btrim(version_label) <> ''),
    CONSTRAINT ck_product_version_dates CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE TABLE titan_core.product_composition (
    product_composition_id text PRIMARY KEY,
    product_version_id text NOT NULL REFERENCES titan_core.product_version(product_version_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    material_id text NOT NULL REFERENCES titan_core.material_master(material_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_constraint_text text NULL,
    mass_share numeric(12,10) NULL CHECK (mass_share IS NULL OR mass_share BETWEEN 0 AND 1),
    min_mass_share numeric(12,10) NULL CHECK (min_mass_share IS NULL OR min_mass_share BETWEEN 0 AND 1),
    max_mass_share numeric(12,10) NULL CHECK (max_mass_share IS NULL OR max_mass_share BETWEEN 0 AND 1),
    composition_basis text NOT NULL DEFAULT 'MASS',
    CONSTRAINT ck_product_composition_id CHECK (product_composition_id ~ '^COMP-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_product_composition_range CHECK (
        min_mass_share IS NULL OR max_mass_share IS NULL OR max_mass_share >= min_mass_share
    ),
    CONSTRAINT uq_product_material UNIQUE(product_version_id,material_id,source_constraint_text)
);

CREATE OR REPLACE FUNCTION titan_core.validate_product_composition_total()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    pv text;
    total_share numeric;
BEGIN
    pv := COALESCE(NEW.product_version_id, OLD.product_version_id);
    SELECT COALESCE(sum(mass_share),0)
      INTO total_share
      FROM titan_core.product_composition
     WHERE product_version_id=pv
       AND mass_share IS NOT NULL;
    IF total_share > 1.0000000001 THEN
        RAISE EXCEPTION 'Product version % mass shares exceed 1.0: %', pv, total_share;
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER ct_product_composition_total
AFTER INSERT OR UPDATE OR DELETE ON titan_core.product_composition
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_product_composition_total();

CREATE TABLE titan_core.product_manufacturing (
    product_manufacturing_id text PRIMARY KEY,
    product_version_id text NOT NULL REFERENCES titan_core.product_version(product_version_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    plant_id text NOT NULL REFERENCES titan_core.plant_master(plant_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    valid_from date NOT NULL,
    valid_to date NULL,
    source_id text NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_product_manufacturing_id CHECK (product_manufacturing_id ~ '^PMR-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_product_manufacturing_dates CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE TABLE titan_core.epd_master (
    epd_id text PRIMARY KEY REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    programme_name text NOT NULL,
    registration_number text NOT NULL,
    epd_type_code text NOT NULL REFERENCES titan_ref.epd_type(epd_type_code),
    valid_from date NOT NULL,
    valid_to date NOT NULL,
    pcr_version_ref text NOT NULL,
    gpi_version_ref text NULL,
    declared_or_functional_unit text NOT NULL,
    lifecycle_scope text NOT NULL,
    epd_notes text NULL,
    CONSTRAINT ck_epd_registration CHECK (btrim(registration_number) <> ''),
    CONSTRAINT ck_epd_dates CHECK (valid_to >= valid_from),
    CONSTRAINT ck_epd_pcr CHECK (btrim(pcr_version_ref) <> ''),
    CONSTRAINT ck_epd_declared_unit CHECK (btrim(declared_or_functional_unit) <> ''),
    CONSTRAINT ck_epd_scope CHECK (btrim(lifecycle_scope) <> '')
);

CREATE TRIGGER trg_epd_master_type
BEFORE INSERT OR UPDATE ON titan_core.epd_master
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_child_entity_type('epd_id','EPD');

CREATE TABLE titan_core.epd_member (
    epd_member_id text PRIMARY KEY,
    epd_id text NOT NULL REFERENCES titan_core.epd_master(epd_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    member_entity_id text NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    product_version_id text NULL REFERENCES titan_core.product_version(product_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    weighting_method text NULL,
    weighting_share numeric(12,10) NULL CHECK (weighting_share IS NULL OR weighting_share BETWEEN 0 AND 1),
    member_notes text NULL,
    CONSTRAINT ck_epd_member_id CHECK (epd_member_id ~ '^EPM-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_epd_member_exactly_one CHECK (
        (member_entity_id IS NOT NULL AND product_version_id IS NULL)
        OR
        (member_entity_id IS NULL AND product_version_id IS NOT NULL)
    )
);

CREATE TABLE titan_core.epd_result (
    epd_result_id text PRIMARY KEY,
    epd_id text NOT NULL REFERENCES titan_core.epd_master(epd_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    observation_id text NOT NULL UNIQUE REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    indicator_code text NOT NULL,
    impact_method_version text NOT NULL,
    lifecycle_module text NOT NULL,
    CONSTRAINT ck_epd_result_id CHECK (epd_result_id ~ '^EPDR-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_epd_indicator CHECK (btrim(indicator_code) <> ''),
    CONSTRAINT ck_epd_method CHECK (btrim(impact_method_version) <> ''),
    CONSTRAINT ck_epd_module CHECK (btrim(lifecycle_module) <> '')
);

CREATE TABLE titan_core.comparability_rule (
    comparability_rule_id text PRIMARY KEY,
    metric_family text NOT NULL,
    rule_version text NOT NULL,
    required_same_fields jsonb NOT NULL DEFAULT '[]'::jsonb,
    allowed_alignment_fields jsonb NOT NULL DEFAULT '[]'::jsonb,
    prohibited_mixes jsonb NOT NULL DEFAULT '[]'::jsonb,
    rule_notes text NULL,
    CONSTRAINT ck_comparability_rule_id CHECK (comparability_rule_id ~ '^CMP-RULE-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_comparability_metric CHECK (btrim(metric_family) <> ''),
    CONSTRAINT ck_comparability_rule_version CHECK (btrim(rule_version) <> '')
);

CREATE TABLE titan_core.normalization_method (
    normalization_method_id text PRIMARY KEY,
    normalization_name text NOT NULL,
    source_basis text NOT NULL,
    target_basis text NOT NULL,
    formula_text text NOT NULL,
    assumptions_text text NOT NULL,
    methodology_version_id text NULL REFERENCES titan_core.methodology_version(methodology_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_normalization_id CHECK (normalization_method_id ~ '^NORM-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_normalization_name CHECK (btrim(normalization_name) <> ''),
    CONSTRAINT ck_normalization_formula CHECK (btrim(formula_text) <> '')
);

CREATE TABLE titan_core.comparison_result (
    comparison_id text PRIMARY KEY,
    comparability_rule_id text NOT NULL REFERENCES titan_core.comparability_rule(comparability_rule_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    observation_a_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    observation_b_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    comparability_result_code text NOT NULL REFERENCES titan_ref.comparability_result(comparability_result_code),
    failure_reason_codes jsonb NOT NULL DEFAULT '[]'::jsonb,
    normalization_method_id text NULL REFERENCES titan_core.normalization_method(normalization_method_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    analytical_purpose text NOT NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_comparison_id CHECK (comparison_id ~ '^CMPR-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_comparison_not_self CHECK (observation_a_id <> observation_b_id),
    CONSTRAINT ck_comparison_purpose CHECK (btrim(analytical_purpose) <> ''),
    CONSTRAINT ck_comparison_normalization CHECK (
        comparability_result_code <> 'CONDITIONALLY_COMPARABLE'
        OR normalization_method_id IS NOT NULL
    )
);


CREATE OR REPLACE FUNCTION titan_core.basic_observation_comparability(
    observation_a text,
    observation_b text
)
RETURNS text
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    a_unit text;
    b_unit text;
    a_den text;
    b_den text;
    a_kind text;
    b_kind text;
    a_method text;
    b_method text;
    a_basis text;
    b_basis text;
    a_boundary_type text;
    b_boundary_type text;
BEGIN
    SELECT o.unit_code, o.denominator_id, o.quantity_kind_code, o.methodology_version_id,
           o.measurement_basis_id, bm.boundary_type_code
      INTO a_unit, a_den, a_kind, a_method, a_basis, a_boundary_type
      FROM titan_core.observation o
      LEFT JOIN titan_core.boundary_version bv ON bv.boundary_version_id=o.boundary_version_id
      LEFT JOIN titan_core.boundary_master bm ON bm.boundary_id=bv.boundary_id
     WHERE o.observation_id=observation_a;

    SELECT o.unit_code, o.denominator_id, o.quantity_kind_code, o.methodology_version_id,
           o.measurement_basis_id, bm.boundary_type_code
      INTO b_unit, b_den, b_kind, b_method, b_basis, b_boundary_type
      FROM titan_core.observation o
      LEFT JOIN titan_core.boundary_version bv ON bv.boundary_version_id=o.boundary_version_id
      LEFT JOIN titan_core.boundary_master bm ON bm.boundary_id=bv.boundary_id
     WHERE o.observation_id=observation_b;

    IF a_kind IS DISTINCT FROM b_kind THEN RETURN 'QUANTITY_KIND_MISMATCH'; END IF;
    IF a_unit IS DISTINCT FROM b_unit THEN RETURN 'UNIT_MISMATCH'; END IF;
    IF a_den IS DISTINCT FROM b_den THEN RETURN 'DENOMINATOR_MISMATCH'; END IF;
    IF a_method IS DISTINCT FROM b_method THEN RETURN 'METHODOLOGY_VERSION_MISMATCH'; END IF;
    IF a_boundary_type IS DISTINCT FROM b_boundary_type THEN RETURN 'BOUNDARY_TYPE_MISMATCH'; END IF;
    IF a_basis IS DISTINCT FROM b_basis THEN RETURN 'MEASUREMENT_BASIS_MISMATCH'; END IF;
    RETURN 'LIKE_FOR_LIKE';
END;
$$;

COMMIT;

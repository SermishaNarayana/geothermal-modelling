from snakemake.utils import min_version

min_version("6.0")

import sys
import pathlib

sys.path.append("workflow/pypsa-earth")
sys.path.append("workflow/pypsa-earth/scripts")


configfile: "workflow/pypsa-earth/config.default.yaml"
configfile: "workflow/pypsa-earth/configs/bundle_config.yaml"
configfile: "configs/config.usa_baseline.yaml"


module pypsa_earth:
    snakefile:
        "workflow/pypsa-earth/Snakefile"
    config:
        config
    prefix:
        "workflow/pypsa-earth"


use rule * from pypsa_earth exclude copy_custom_powerplants, build_demand_profiles


demand_year = config["US"]["demand_year"]
run_name = config["run"]["name"]
SECDIR = config["sector_name"] + "/" if config.get("sector_name") else ""


localrules:
    all,


rule copy_custom_powerplants:
    input:
        "data/custom_powerplants_eia.csv",
    output:
        "workflow/pypsa-earth/data/custom_powerplants.csv",
    shell:
        "cp {input} {output}"


rule build_custom_powerplants:
    input:
        eia_generators_data_path=pathlib.Path(
            "analysis",
            "gdrive_data",
            "data",
            "powerplant_data",
            "EIA_generators",
            "eia8602021",
            "3_1_Generator_Y2021.xlsx",
        ),
        eia_plants_data_path=pathlib.Path(
            "analysis",
            "gdrive_data",
            "data",
            "powerplant_data",
            "EIA_generators",
            "eia8602021",
            "2___Plant_Y2021.xlsx",
        ),
        ror_custom_powerplants_path=pathlib.Path(
            "analysis",
            "gdrive_data",
            "data",
            "powerplant_data",
            "custom_powerplants_ror.csv",
        ),
    output:
        output_file_path=pathlib.Path("data", "custom_powerplants_eia.csv"),
    script:
        "analysis/scripts/build_custom_powerplants.py"


if config["US"].get("retrieve_US_databundle", True):

    rule retrieve_data:
        params:
            gdrive_url="https://drive.google.com/drive/folders/1sWDPC1EEzVtgixBb8C-OqZiEX3dmTOec",
            cookies_path=pathlib.Path(".cache", "gdown"),
            output_directory=pathlib.Path("analysis", "gdrive_data", "data"),
            delta_months=5,
        output:
            expand(
                "analysis/gdrive_data/data/powerplant_data/{filename}",
                filename=[
                    "EIA_generators/eia8602021/3_1_Generator_Y2021.xlsx",
                    "EIA_generators/eia8602021/2___Plant_Y2021.xlsx",
                    "custom_powerplants_ror.csv",
                    "capacities_eia.xlsx",
                    "existcapacity_annual.xlsx",
                    "custom_powerplants_eia_with_state.csv",
                ],
            ),
            expand(
                "analysis/gdrive_data/data/transmission_grid_data/{filename}",
                filename=[
                    "US_electric_transmission_lines_original.geojson",
                    "transmission_single_epaipm.csv",
                ],
            ),
            expand(
                "analysis/gdrive_data/data/pypsa_usa/{filename}",
                filename=[
                    "lines_gis.csv",
                    "Reeds_Shapes/rb_and_ba_areas.shp",
                    "transmission/transmission_capacity_init_AC_ba_NARIS2024.csv",
                ],
            ),
            expand(
                "analysis/gdrive_data/data/shape_files/{filename}",
                filename=[
                    "gadm41_USA_1.json",
                    "ipm_v6_regions/IPM_Regions_201770405.shp",
                    "Balancing_Authorities.geojson",
                ],
            ),
            expand(
                "analysis/gdrive_data/data/electricity_generation_data/{filename}",
                filename=[
                    "EIA_statewise_data/use_all_phy_update.xlsx",
                    "generation_eia.csv",
                ],
            ),
            expand(
                "analysis/gdrive_data/data/electricity_demand_data/{filename}",
                filename=[
                    "use_es_capita.xlsx",
                    "EIA930_2021_Jan_Jun_opt.csv",
                    "EIA930_2021_Jul_Dec_opt.csv",
                    "HS861 2010-.xlsx",
                ],
            ),
            directory(
                pathlib.Path(
                    "analysis",
                    "gdrive_data",
                    "data",
                    "electricity_demand_data",
                    "future_demand_projections",
                )
            ),
        script:
            "analysis/scripts/download_from_gdrive.py"


if config["US"].get("network_comparison", True):

    rule network_comparison:
        params:
            plot_network_topology=True,  # Boolean: plot the network topology
            plot_network_crossings=True,  # Boolean: plot the network crossings
            plot_network_capacity_ipm=True,  # Boolean: plot the network capacity for the PyPSA vs IPM case
            plot_network_capacity_reeds=True,  # Boolean: plot the network capacity for the PyPSA vs reeds case
        input:
            base_network_pypsa_earth_path=pathlib.Path(
                "workflow", "pypsa-earth", "networks", run_name, "base.nc"
            ),
            base_network_pypsa_usa_path=pathlib.Path(
                "analysis", "gdrive_data", "data", "pypsa_usa", "lines_gis.csv"
            ),
            eia_base_network_path=pathlib.Path(
                "analysis",
                "gdrive_data",
                "data",
                "transmission_grid_data",
                "US_electric_transmission_lines_original.geojson",
            ),
            gadm_shapes_path=pathlib.Path(
                "analysis", "gdrive_data", "data", "shape_files", "gadm41_USA_1.json"
            ),
            ipm_shapes_path=pathlib.Path(
                "analysis",
                "gdrive_data",
                "data",
                "shape_files",
                "ipm_v6_regions",
                "IPM_Regions_201770405.shp",
            ),
            lines_osm_raw_path=pathlib.Path(
                "workflow",
                "pypsa-earth",
                "resources",
                run_name,
                "osm",
                "raw",
                "all_raw_lines.geojson",
            ),
            lines_osm_clean_path=pathlib.Path(
                "workflow",
                "pypsa-earth",
                "resources",
                run_name,
                "osm",
                "clean",
                "all_clean_lines.geojson",
            ),
            reeds_shapes_path=pathlib.Path(
                "analysis",
                "gdrive_data",
                "data",
                "pypsa_usa",
                "Reeds_Shapes",
                "rb_and_ba_areas.shp",
            ),
            ipm_capacities_path=pathlib.Path(
                "analysis",
                "gdrive_data",
                "data",
                "transmission_grid_data",
                "transmission_single_epaipm.csv",
            ),
            reeds_capacities_path=pathlib.Path(
                "analysis",
                "gdrive_data",
                "data",
                "pypsa_usa",
                "transmission",
                "transmission_capacity_init_AC_ba_NARIS2024.csv",
            ),
        output:
            directory(pathlib.Path("analysis", "outputs", "network_comparison")),
        script:
            "analysis/scripts/network_comparison.py"


if config["cluster_options"].get("alternative_clustering", True):
    network_path = (
        expand(
            pathlib.Path(
                "workflow",
                "pypsa-earth",
                "results",
                run_name,
                "networks",
                "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}.nc",
            ),
            **config["scenario"],
        ),
    )
    installed_capacity_comparison_plot_folder_name = "installed_capacity_ac"
else:
    network_path = (
        expand(
            pathlib.Path(
                "analysis",
                "outputs",
                "map_network_to_gadm",
                "elec_s{simpl}_gadm_mapped.nc",
            ),
            **config["scenario"],
        ),
    )
    installed_capacity_comparison_plot_folder_name = "installed_capacity_nonac"


if config["US"].get("installed_capacity_comparison", True):

    rule installed_capacity_comparison:
        params:
            year_for_comparison=demand_year,
            plot_country_comparison=True,  # Boolean: plot the countrywide generation comparison
            plot_state_by_state_comparison=True,  # Boolean: plot the state-by-state generation comparison
            plot_spatial_representation=True,  # Boolean: plot the map with the installed capacity per node
            state_to_omit=["AK", "HI"],
        input:
            eia_installed_capacity_path=pathlib.Path(
                "analysis",
                "gdrive_data",
                "data",
                "powerplant_data",
                "capacities_eia.xlsx",
            ),
            eia_state_temporal_installed_capacity_path=pathlib.Path(
                "analysis",
                "gdrive_data",
                "data",
                "powerplant_data",
                "existcapacity_annual.xlsx",
            ),
            eia_raw_reference_path=pathlib.Path(
                "analysis",
                "gdrive_data",
                "data",
                "powerplant_data",
                "custom_powerplants_eia_with_state.csv",
            ),
            gadm_shapes_path=pathlib.Path(
                "analysis", "gdrive_data", "data", "shape_files", "gadm41_USA_1.json"
            ),
            pypsa_earth_network_path=network_path,
        output:
            plot_path=directory(
                pathlib.Path(
                    "analysis", "plots", installed_capacity_comparison_plot_folder_name
                )
            ),
        script:
            "analysis/scripts/installed_capacity_comparison.py"


if config["cluster_options"].get("alternative_clustering", False):

    rule map_network_to_gadm:
        input:
            gadm_shapes_path=pathlib.Path(
                "analysis", "gdrive_data", "data", "shape_files", "gadm41_USA_1.json"
            ),
            pypsa_earth_network_path=expand(
                pathlib.Path(
                    "workflow",
                    "pypsa-earth",
                    "networks",
                    run_name,
                    "elec_s{simpl}.nc",
                ),
                **config["scenario"],
            ),
        output:
            mapped_network_output_file_path=expand(
                pathlib.Path(
                    "analysis",
                    "outputs",
                    "map_network_to_gadm",
                    "elec_s{simpl}_gadm_mapped.nc",
                ),
                **config["scenario"],
            ),
        script:
            "analysis/scripts/map_network_to_gadm.py"


if config["US"].get("generation_comparison", True):

    rule generation_comparison:
        params:
            year_for_comparison=demand_year,
            plot_country_comparison=True,  # Boolean: plot the countrywide generation comparison
            plot_state_by_state_comparison=True,  # Boolean: plot the state-by-state generation comparison
        input:
            eia_country_generation_path=pathlib.Path(
                "analysis",
                "gdrive_data",
                "data",
                "electricity_generation_data",
                "generation_eia.csv",
            ),
            eia_state_generation_path=pathlib.Path(
                "analysis",
                "gdrive_data",
                "data",
                "electricity_generation_data",
                "EIA_statewise_data",
                "use_all_phy_update.xlsx",
            ),
            gadm_shapes_path=pathlib.Path(
                "analysis", "gdrive_data", "data", "shape_files", "gadm41_USA_1.json"
            ),
            pypsa_earth_network_path=expand(
                pathlib.Path(
                    "workflow",
                    "pypsa-earth",
                    "results",
                    run_name,
                    "networks",
                    "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}.nc",
                ),
                **config["scenario"],
            ),
        output:
            directory(pathlib.Path("analysis", "plots", "generation_comparison")),
        script:
            "analysis/scripts/generation_comparison.py"


rule preprocess_demand_data:
    params:
        demand_year=config["US"]["demand_year"],
        holes_area_threshold=config["US"]["demand_modelling"]["holes_area_threshold"],  # to ignore holes smaller than this area in sq.km (CRS 6372)
        nprocesses=config["US"]["demand_modelling"]["nprocesses"],
        plotting=config["US"]["demand_modelling"]["plotting"],
        geo_crs=config["crs"]["geo_crs"],
        distance_crs=config["crs"]["distance_crs"],
        area_crs=config["US"]["area_crs"],
    input:
        demand_utility_path=pathlib.Path(
            "analysis",
            "gdrive_data",
            "data",
            "electricity_demand_data",
            "demand_data",
            "table_10_EIA_utility_sales.xlsx",
        ),
        country_gadm_path=pathlib.Path(
            "workflow",
            "pypsa-earth",
            "resources",
            run_name,
            "shapes",
            "country_shapes.geojson",
        ),
        erst_path=pathlib.Path(
            "analysis",
            "gdrive_data",
            "data",
            "electricity_demand_data",
            "demand_data",
            "Electric_Retail_Service_Territories.geojson",
        ),
        gadm_usa_path=pathlib.Path(
            "analysis", "gdrive_data", "data", "shape_files", "gadm41_USA_1.json"
        ),
        eia_per_capita_path=pathlib.Path(
            "analysis",
            "gdrive_data",
            "data",
            "electricity_demand_data",
            "use_es_capita.xlsx",
        ),
        additional_demand_data_path=pathlib.Path(
            "analysis",
            "gdrive_data",
            "data",
            "electricity_demand_data",
            "HS861 2010-.xlsx",
        ),
    output:
        utility_demand_path=pathlib.Path(
            "analysis",
            "outputs",
            "demand_modelling",
            "ERST_mapped_demand_centroids.geojson",
        ),
    script:
        "analysis/scripts/preprocess_demand_data.py"


rule build_demand_profiles_from_eia:
    params:
        geo_crs=config["crs"]["geo_crs"],
        distance_crs=config["crs"]["distance_crs"],
        demand_horizon=config["US"]["demand_projection"]["planning_horizon"],
        demand_scenario=config["US"]["demand_projection"]["scenario"],
    input:
        BA_demand_path1=expand(
            pathlib.Path(
                "analysis",
                "gdrive_data",
                "data",
                "electricity_demand_data",
                "EIA930_{demand_year}_Jan_Jun_opt.csv",
            ),
            **config["US"],
        ),
        BA_demand_path2=expand(
            pathlib.Path(
                "analysis",
                "gdrive_data",
                "data",
                "electricity_demand_data",
                "EIA930_{demand_year}_Jul_Dec_opt.csv",
            ),
            **config["US"],
        ),
        BA_shape_path=pathlib.Path(
            "analysis",
            "gdrive_data",
            "data",
            "shape_files",
            "Balancing_Authorities.geojson",
        ),
        utility_demand_path=pathlib.Path(
            "analysis",
            "outputs",
            "demand_modelling",
            "ERST_mapped_demand_centroids.geojson",
        ),
        pypsa_network_path=(
            pathlib.Path("workflow", "pypsa-earth", "networks", run_name, "base.nc"),
        ),
        gadm_shape=pathlib.Path(
            "analysis", "gdrive_data", "data", "shape_files", "gadm41_USA_1.json"
        ),
        demand_projections_path=pathlib.Path(
            "analysis",
            "gdrive_data",
            "data",
            "electricity_demand_data",
            "future_demand_projections",
        ),
    output:
        demand_profile_path=pathlib.Path(
            "workflow", "pypsa-earth", "resources", run_name, "demand_profiles.csv"
        ),
    script:
        "analysis/scripts/build_demand_profiles_from_eia.py"


rule modify_energy_totals:
    params:
        country=config["countries"],
    input:
        demand_profile_path=pathlib.Path(
            "workflow", "pypsa-earth", "resources", run_name, "demand_profiles.csv"
        ),
        energy_totals_path=expand(
            pathlib.Path(
                "workflow",
                "pypsa-earth",
                "resources",
                SECDIR,
                "energy_totals_{demand}_{planning_horizons}.csv",
            ),
            **config["scenario"],
        ),
        industrial_demand_path=expand(
            pathlib.Path(
                "workflow",
                "pypsa-earth",
                "resources/",
                SECDIR,
                "demand/industrial_energy_demand_per_node_elec_s{simpl}_{clusters}_{planning_horizons}_{demand}.csv",
            ),
            **config["scenario"],
            **config["costs"],
            **config["export"],
        ),
    output:
        energy_totals_path=expand(
            pathlib.Path(
                "workflow",
                "pypsa-earth",
                "resources",
                SECDIR,
                "energy_totals_{demand}_{planning_horizons}_updated.csv",
            ),
            **config["scenario"],
        ),
    script:
        "analysis/scripts/modify_energy_totals.py"


rule replace_energy_totals:
    input:
        energy_totals_path=expand(
            pathlib.Path(
                "workflow",
                "pypsa-earth",
                "resources",
                SECDIR,
                "energy_totals_{demand}_{planning_horizons}_updated.csv",
            ),
            **config["scenario"],
        ),
    output:
        energy_totals_path=expand(
            pathlib.Path(
                "workflow",
                "pypsa-earth",
                "resources",
                SECDIR,
                "energy_totals_{demand}_{planning_horizons}.csv",
            ),
            **config["scenario"],
        ),
    shell:
        "cp {input} {output}"


rule plot_and_extract_summaries:
    params:
        energy_carriers=config["US"]["summary"]["energy_carriers"],
    input:
        pypsa_earth_results_path=expand(
            pathlib.Path(
                "workflow",
                "pypsa-earth",
                "results",
                "postnetworks",
                "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}_{demand}_{h2export}export.nc",
            ),
            **config["scenario"],
            **config["costs"],
            **config["export"],
        ),
    output:
        plot_path=directory(pathlib.Path("analysis", "plots", "summary_plots")),
        output_path=directory(pathlib.Path("analysis", "outputs", "summary_outputs")),
    script:
        "analysis/scripts/plot_and_extract_summaries.py"


rule summary:
    input:
        pathlib.Path("analysis", "plots", "generation_comparison")
        if config["US"]["summary"]["generation_comparison"]
        else [],
        pathlib.Path(
            "analysis", "plots", installed_capacity_comparison_plot_folder_name
        )
        if config["US"]["summary"]["installed_capacity_comparison"]
        else [],
        pathlib.Path("analysis", "outputs", "network_comparison")
        if config["US"]["summary"]["network_comparison"]
        else [],
        expand(
            pathlib.Path("analysis", "outputs", "{filedir}"),
            filedir=["demand_modelling/ERST_mapped_demand_centroids.geojson"],
        ),
        pathlib.Path(
            "workflow", "pypsa-earth", "resources", run_name, "demand_profiles.csv"
        ),
        expand(
            pathlib.Path(
                "workflow",
                "pypsa-earth",
                "results",
                "postnetworks",
                "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}_{demand}_{h2export}export.nc",
            ),
            **config["scenario"],
            **config["costs"],
            **config["export"],
        ),
        pathlib.Path("analysis", "plots", "summary_plots"),

extends RefCounted

const PROFILES := {
	"Conveyor": &"machine", "Foundry-Press": &"steam", "Foundry-Gear": &"machine",
	"Machine-Unit": &"steam", "Foundry-Furnace": &"heat", "Foundry-Pipe-Valve": &"steam",
	"Pipe-Cluster": &"steam", "pipe_elbow": &"steam", "pipe_end": &"steam",
	"Cable-Coil": &"spark", "Broken-Robot": &"spark",
	"Identity-archive_access_panel_broken": &"spark",
	"Terminal": &"signal", "Archive-Terminal": &"signal",
	"Data-Storage-Rack": &"signal", "Archive-Data-Vault": &"signal",
	"SciFi-Lamp": &"lamp", "Foundry-Lamp": &"lamp",
	"Hologram-Projector": &"hologram", "Archive-Holo-Projector": &"hologram",
	"Core-Hologram-Dais": &"hologram", "Core-Generator": &"reactor", "Core-Reactor": &"reactor",
	"Identity-core_data_cabinet_low": &"signal", "Identity-core_light_trim": &"signal",
	"Core-Portal-Frame": &"hologram", "Sanctuary-Shrine": &"hologram",
	"Narrative-soul_archive": &"signal", "Narrative-eva_conduit": &"signal",
	"Narrative-judgement_engine": &"signal", "Narrative-silence_reliquary": &"hologram",
	"Narrative-elias_testament": &"signal", "Archive-Plinth": &"hologram",
	"Plant-Cluster": &"wind", "Sanctuary-Tree": &"wind", "Sanctuary-Vine-Arch": &"wind",
	"Sanctuary-Pool": &"water", "Portal": &"water",
	"Energy-Core": &"energy", "Core-Pedestal": &"energy", "Memory-Fragment": &"energy",
	"Energy-Cable": &"signal", "Switch": &"signal", "energy_node": &"node",
	"Pressure-Plate": &"plate",
}

const ANIMATED_NAMES := [
	"Conveyor", "Foundry-Press", "Foundry-Gear", "Machine-Unit", "Hologram-Projector",
	"Archive-Holo-Projector", "Core-Reactor", "Core-Generator", "Core-Hologram-Dais",
	"Plant-Cluster", "Sanctuary-Tree", "Sanctuary-Vine-Arch", "Sanctuary-Shrine",
	"Energy-Core", "Core-Pedestal", "Terminal", "Memory-Fragment", "Pressure-Plate",
]


static func profile_for(path: String, chapter := 0) -> StringName:
	var name := path.get_file().get_basename()
	if name == "Machine-Unit" and chapter == 1:
		return &"signal"
	if name.begins_with("water_"):
		return &"water"
	return PROFILES.get(name, &"")

/** 
 * The Level state
 *
 * @public
 * @constructor module:Level
 * @extends module:State
 * @author Riko Ophorst
 */
var Level = Level || function()
{
	Level._super.constructor.call(this, arguments);
};

_.inherit(Level, State);

_.extend(Level.prototype, {
	init: function ()
	{
		Level._super.init.call(this);

		this._light = new Light(LightType.Directional);
		this._light.setDirection(0, -1, -1);
	},

	show: function()
	{
		Level._super.show.call(this);

		this._editMode = CVar.get("editMode") == true;

		Lighting.setAmbientColour(0.3, 0.2, 0.1);
		Lighting.setShadowColour(0.2, 0.3, 0.5);

		RenderTargets.water.setPostProcessing("effects/water.effect");
		RenderTargets.water.setTechnique("PostProcess");

		/**
		* The map
		*/
		this._map = this.world.spawn("entities/world/visual/world_map.json", { 
			editMode: this._editMode
		});

		/**
		* The camera
		*/
		this._camera = this.world.spawn("entities/world/gameplay/camera_control.json", { 
			camera: Game.camera, 
			editMode: this._editMode
		});

		/**
		* The grid
		*/
		this._grid = this.world.spawn("entities/world/utility/grid.json", {
			map: this._map
		});
		this._map._grid = this._grid;

		if (this._editMode == true)
		{
			this._editor = this.world.spawn("entities/editor/editor.json", { 
				map: this._map, 
				camera: this._camera,
				view: this.view
			});
			this._map.setEditor(this._editor);
			this._editor._grid = this._grid;
		}
		else
		{
			this.view.root_world.destroy();
		}

		this._map.initialise();
		this._grid.calculate();

		if (this._editMode == true)
		{
			this._editor.initialise();
		}

		if (IO.exists("json/map/map.json") == true)
		{
			this._map.load();
		}
	},

	update: function (dt)
	{
		Level._super.update.call(this, dt);
	},

	draw: function ()
	{
		Level._super.draw.call(this);

		Game.render(Game.camera, RenderTargets.default);
		Game.render(Game.camera, RenderTargets.water);
		Game.render(Game.camera, RenderTargets.ui);
		RenderTargets.shore.clearAlbedo();
	}
});
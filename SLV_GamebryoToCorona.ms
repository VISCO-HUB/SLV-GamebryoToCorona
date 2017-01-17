/*
[INFO]

NAME = GamebryoToCorona
VERSION = 1.1.6
AUTHOR = Vasiliy Lukyanenko
DEV = VISCO
HELP = 


[1.0.1]
	
	* First Release	=	
[1.0.2]

	-BugFix: Decal import=

[1.0.3]

	+ Set blur for textures 0.2=

[1.1.0 ]

	+ Added Help=

[1.1.1]

	-BugFix: No collapse vertex color modificator=
	+ Set blur for normal 0.6=

[1.1.2]

	- BugFix: Create dublicate id in multmaterial=

[1.1.3]

- BugFix: Materials Names=

[1.1.4]

	- BugFix: Scene paths = 
	- BugFix: Adopted for new Corona =
	
[1.1.5]
	
	- BugFix: Map channel for DecalMaps=
	
[1.1.6]
	
	- BugFix: Fix opacity for Corona Renderer 1.3=

[ABOUT]

This script helps convert materials =
from GameBryo to Corona Renderer.=
_______________________________________=		
How to use:=
1. Open scene in 3DsMax 2012 =
2. Run this script and press Export=
3. Open scene in 3DsMax 2014=
4. Run this script and press Import=
		
All materials will be converted.=

[SCRIPT]
*/

fn getScriptInfo s releaseInfo: "" =
(		
	if(releaseInfo != "") do
	(
		r = getINISetting s releaseInfo
		return r
	)
	
	v = getINISetting s "INFO" "VERSION"
	a = getINISetting s "INFO" "AUTHOR"
	n = getINISetting s "INFO" "NAME"
	o = getINISetting s "ABOUT"
	c = getINISetting s "INFO" "DEV"
	h = getINISetting s "INFO" "HELP"
	
	r = for i in (getINISetting s) where i != "ABOUT" and i != "SCRIPT" and i != "COPY" collect i
	
	return #(n, a, v, o, r, c, h)
)

fn parseToLine m = 
(
	if(m.count == 0) do return ""
	
	l = ""				
	for i in m do 
	(	
		if(i[1] == "_") do l += "_______________________________________"
		l += i + "\n"
	)
	return l
)

try(closeRolloutFloater rGamebryoToCorona) catch()


global rGamebryoToCorona = newRolloutFloater "GB -> Corona" 200 330
global szDefPath = @"C:\temp\coronaMTL.cml"
global szDefMaxPath = @"c:\temp\clipboard.max"

rollout rGB_Corona "Export / Import"
(
/*   
=====================================================================================
	MAIN FUNCTIONS
=====================================================================================
*/
	
	button btnExportImport "Export" height: 45 width: 180
	group "Info:"
	(
		label lblInfo "" height: 60 width: 165 style_sunkenedge: false 
	)
	
	group "Materials Defaults"
	(
		spinner spnDiffuseLevel "Diffuse Level: " range:[0.0,1.0,0.65] scale:0.1 align: #left width: 80 type:#float
		spinner spnRGBLevel "RGB Level: " range:[-100,100,1.0] scale:0.1 align: #left width: 80 type:#float
	)
	
	group "Settings"
	(
		checkbox cbxTexInVieport "Show textures in Viewport" checked: true
		checkbox cbxUpdateVC "Update Objects Vertex Colors" checked: true
	)

	fn is2012 =
	(
		v = maxVersion()
		if(v[1] / 1000 == 14) do return true
		return false	
	)

	fn isCorona =
	(
		r = renderers.current as string
		if matchpattern r pattern:"*CoronaRenderer*" then return true else return false
	)
	
	fn isGB m =
	(
		return (classOf m == Standardmaterial and m.ShaderByName == "Gamebryo Shader")
	)
	
	fn stipChars n =
	(
		s = ""
		for i in (filterString n "#\\!@$\%^&*()_+[]{}\"\':;,.<>`~") do s += i
		return s
	)
	
	fn getTextures m =
	(
		textureList = #(#(), #())
		
		for b in getClassInstances bitmaptex target:m asTrackViewPick:true do
		(				
			f = b.anim.filename
			c = b.anim.coordinates.mapChannel
			case b.subnum of
			(
				/*
					2 - Diffuse : [1]
					4 - Dark : [2]
					6 - Detail: [3]
					8 - Decal: [4]
					16 - Gloss: [5]
					10 - Normal: [6]
				*/
				2:
				(
					textureList[1][1] = f
					textureList[2][1] = c
				)
				4:
				(	
					textureList[1][2] = f
					textureList[2][2] = c
				)
				6: 
				(
					textureList[1][3] = f
					textureList[2][3] = c	
				)
				8:
				(
					textureList[1][4] = f
					textureList[2][4] = c
				)
				16:
				(		
					textureList[1][5] = f
					textureList[2][5] = c
				)					
				10:
				(				
					textureList[1][6] = f
					textureList[2][6] = c
				)
			)			
		)
		
		return textureList
	)
	
	fn createBitmap b c blurTex: 0.2 =
	(
		bmt = Bitmaptexture filename: b name: (getFilenameFile b)
		
		if(c == undefined) do c = 1
		
		bmt.coordinates.mapChannel = c
		bmt.coords.blur = blurTex
		bmt.output.rgb_level = spnRGBLevel.value
		
		return bmt
	)
	
	fn getExportChannel c =
	(		
		if(c == "undefined") do return 1
		return c as integer		
	)
	
/*   
=====================================================================================
	EXPORT
=====================================================================================
*/
	
	fn exportMtl p f =
	(	
		if(maxFilePath == undefined) do 
		(
			messageBox "Please save scene!" title: "Warning!"
			return false
		)
			
		mtl = sceneMaterials[p]
		
		if(mtl == undefined) do return false
		
		local m = #()
		local id = #()
		
		if(classOf mtl == MultiMaterial) then
		(		
			m = mtl.materialList
			id = mtl.materialIDList
		)
		else if (isGB mtl) then
		(			
			m[1] = mtl
			id[1] = 0
		)
		
		exportMaterials = ""
		for i in id do exportMaterials += ":" + i as string
		setINISetting f "exportMaterials" mtl.name exportMaterials
				

		
		for i in 1 to id.count do
		(
			if(isGB m[i] == false) do continue
			
			iniMatHeader = mtl.name + ":" + id[i] as string
			
			-- Set Name
			setINISetting f iniMatHeader "name" m[i].name
			-- Set ID
			setINISetting f iniMatHeader "id" (id[i] as string)
			-- Set Diffuse Color
			setINISetting f iniMatHeader "diffuse" (m[i].diffuse as string)
			-- Set Alpha
			setINISetting f iniMatHeader "alpha" (m[i].alpha as string)
			-- Set Shininess
			setINISetting f iniMatHeader "shininess" (m[i].shininess as string)
			-- Set Vertex Color ON/OFF
			setINISetting f iniMatHeader "VertexColorsEnable" (m[i].VertexColorsEnable as string)
			-- Set BAT ON/OFF
			setINISetting f iniMatHeader "BAT" (try(m[i].NiShaderCustAttribs.BAT as string)catch("false"))
			-- Set Custom Shader
			setINISetting f iniMatHeader "CustomShader" (m[i].CustomShader as string)
			-- Set Custom Shader
			setINISetting f iniMatHeader "ReflMap" (try((m[i].NiShaderCustAttribs.ReflMap != undefined) as string)catch("false"))
			-- Set Specular ON/OFF
			setINISetting f iniMatHeader "specularEnable" (m[i].specularEnable as string)
			-- Set Specular Color
			setINISetting f iniMatHeader "Specular" (m[i].Specular as string)
			-- Set Opacity ON/OFF
			setINISetting f iniMatHeader "OpacityEnable" ((m[i].alphaMode != 1) as string)
			
			-- Set Amount
			setINISetting f iniMatHeader "DecalAmount" (try(m[i].DecalAmount as string)catch("100.0"))
			setINISetting f iniMatHeader "DetailAmount" (try(m[i].DetailAmount as string)catch("100.0"))
			setINISetting f iniMatHeader "diffuseMapAmount" (try(m[i].diffuseMapAmount as string)catch("100.0"))
			setINISetting f iniMatHeader "Dark_Amount" (try(m[i].Dark_Amount as string)catch("100.0"))
			setINISetting f iniMatHeader "Normal_Amount" (try(m[i].Normal_Amount as string)catch("100.0"))
		   
			-- Set Textures Paths
			t = getTextures m[i]
			setINISetting f iniMatHeader "diffuseMap" (t[1][1] as string)			
			setINISetting f iniMatHeader "darkMap" (t[1][2] as string)
			setINISetting f iniMatHeader "detailMap" (t[1][3] as string)
			setINISetting f iniMatHeader "decalMap" (t[1][4] as string)
			setINISetting f iniMatHeader "glossMap" (t[1][5] as string)
			setINISetting f iniMatHeader "normalMap" (t[1][6] as string)

			-- Set Channels
			setINISetting f iniMatHeader "diffuseMapChannel" (t[2][1] as string)			
			setINISetting f iniMatHeader "darkMapChannel" (t[2][2] as string)			
			setINISetting f iniMatHeader "detailMapChannel" (t[2][3] as string)			
			setINISetting f iniMatHeader "decalMapChannel" (t[2][4] as string)			
			setINISetting f iniMatHeader "glossMapChannel" (t[2][5] as string)			
			setINISetting f iniMatHeader "normalMapChannel" (t[2][6] as string)			
		)
		

		progressUpdate (100.0 * p / sceneMaterials.count)	
				
		if(getProgressCancel() == true)do exit			
	)
/*   
=====================================================================================
	IMPORT
=====================================================================================
*/
	
	fn createDiffuse
				gDiffuse 
				gDiffuseMap
				gVertexColorsEnable
				gBAT
				gGlossMap
				gDarkMap
				gDetailMap
				gDecalMap
				gDark_Amount
				gDetailAmount
				gDiffuseMapAmount
				gNormal_Amount
				gDecalAmount
				gDiffuseMapChannel
				gDarkMapChannel
				gDecalMapChannel
				gDetailMapChannel
				gGlossMapChannel = 
	(		
		i = 0
		
		bDiffuseMap = undefined
		outputMap = compositeTextureMap()
		
		-- Layer 1 : DiffuseMap		
		if(gDiffuseMap != "undefined") do
		(
			i += 1
			
			bDiffuseMap = createBitmap gDiffuseMap gDiffuseMapChannel
					
			outputMap.mapList[i] = bDiffuseMap
			
			-- Add color mix
			
			
			if(gDiffuse != white) do
			(
				i += 1
				
				c = ColorCorrection()
				c.color = gDiffuse
				outputMap.mapList[i] = c
				outputMap.blendMode[i] = 5
			)
		)
				
		-- Layer 2 : VertexColor with Mask
		if(gVertexColorsEnable == "true") do
		(
			i += 1	
			
			outputMap.mapList[i] = Vertex_Color ()
			outputMap.blendMode[i] = 5
			
			if(gBAT == "true" and gGlossMap != "undefined") do
			(				
				bGlossMap = createBitmap gGlossMap gGlossMapChannel
				
				outputMap.Mask[i] = Color_Correction ()
				outputMap.Mask[i].rewireR = 6 
				outputMap.Mask[i].rewireG = 6 
				outputMap.Mask[i].rewireB = 6 
				outputMap.Mask[i].hueShift = -0.5
				outputMap.Mask[i].saturation = -0.5
				outputMap.Mask[i].map = bGlossMap							
			)				
		)
		
		-- Layer 3 : Detail	
		if(gDetailMap != "undefined") do
		(
			i += 1
			
			bDetailMap = createBitmap gDetailMap gDetailMapChannel
			
			outputMap.mapList[i] = bDetailMap
			outputMap.opacity[i] = gDetailAmount
			-- BlendMode Multiply
			outputMap.blendMode[i] = 5
		)
		
		-- Layer 4 : DarkMap
		if(gDarkMap != "undefined") do
		(
			i += 1
			
			bDarkMap = createBitmap gDarkMap gDarkMapChannel
			
			outputMap.mapList[i] = bDarkMap
			outputMap.opacity[i] = gDark_Amount
			-- BlendMode Multiply
			outputMap.blendMode[i] = 5
		)
		
		-- Layer 5 : DecalMap
		if(gDecalMap != "undefined") do
		(
			i += 1

			bDecalMap = createBitmap gDecalMap gDecalMapChannel
			outputMap.mapList[i] = bDecalMap
			outputMap.opacity[i] = gDecalAmount
		)			
				
		if(i == 0) do return undefined
		
		return outputMap
	)
	
	fn createReflection gGlossMap gGlossMapChannel gBAT =
	(
		if(gGlossMap != "undefined") do
		(
			if(gBAT == "true") then
			(
				bGlossMap = createBitmap gGlossMap gGlossMapChannel
				
				b = Color_Correction ()
				b.rewireR = 2 
				b.rewireG = 2 
				b.rewireB = 2 
				b.map = bGlossMap	
				
				return b
			)
			
			return createBitmap gGlossMap gGlossMapChannel
		)
		
		return undefined
	)
	
	fn createCoronaMtl f iniMatHeader =
	(			
		m = CoronaMtl()				
		
		/*
		--------------------------------------------------------------------------------------
			IMPORT DATA
		--------------------------------------------------------------------------------------
		*/
		
		gName = getINISetting f iniMatHeader "name"
		gId = getINISetting f iniMatHeader "id" as integer
		gDiffuse = execute(getINISetting f iniMatHeader "diffuse")
		gSpecular = execute(getINISetting f iniMatHeader "Specular")
		gAlpha = getINISetting f iniMatHeader "alpha" as float
		gShininess = getINISetting f iniMatHeader "shininess" as float
		gVertexColorsEnable = getINISetting f iniMatHeader "VertexColorsEnable"
		gBAT = getINISetting f iniMatHeader "BAT"
		gCustomShader = getINISetting f iniMatHeader "CustomShader"
		gReflMap = getINISetting f iniMatHeader "ReflMap"
		gSpecularEnable = getINISetting f iniMatHeader "specularEnable"
		gOpacityEnable = getINISetting f iniMatHeader "OpacityEnable"
		
		-- Get Textures
		gDiffuseMap = getINISetting f iniMatHeader "diffuseMap"
		gDarkMap = getINISetting f iniMatHeader "darkMap"
		gDetailMap = getINISetting f iniMatHeader "detailMap"
		gDecalMap = getINISetting f iniMatHeader "decalMap"
		gGlossMap = getINISetting f iniMatHeader "glossMap"
		gNormalMap = getINISetting f iniMatHeader "normalMap"
		
		-- Get Amount
		gDecalAmount = getINISetting f iniMatHeader "DecalAmount" as float		
		gDark_Amount = getINISetting f iniMatHeader "Dark_Amount" as float * 100.0
		gDetailAmount = getINISetting f iniMatHeader "DetailAmount" as float
		gDiffuseMapAmount = getINISetting f iniMatHeader "diffuseMapAmount" as float
		gNormal_Amount = getINISetting f iniMatHeader "Normal_Amount" as float
		gNormal_Amount = getINISetting f iniMatHeader "Normal_Amount" as float
		
		-- Get Channels
		gDiffuseMapChannel = getExportChannel (getINISetting f iniMatHeader "diffuseMapChannel")		
		gDarkMapChannel = getExportChannel (getINISetting f iniMatHeader "darkMapChannel")
		gDetailMapChannel = getExportChannel (getINISetting f iniMatHeader "detailMapChannel")
		gDecalMapChannel = getExportChannel (getINISetting f iniMatHeader "decalMapChannel")
		gGlossMapChannel = getExportChannel (getINISetting f iniMatHeader "glossMapChannel")
		gNormalMapChannel = getExportChannel (getINISetting f iniMatHeader "normalMapChannel")
		-- Set Name
		m.name = gName
		
		/*
		--------------------------------------------------------------------------------------
			DIFFUSE
		--------------------------------------------------------------------------------------
		*/
		-- Set DiffuseColor
		
		m.colorDiffuse =  gDiffuse
		m.levelDiffuse = spnDiffuseLevel.value
		
		-- Set Diffuse Texture
		d = createDiffuse gDiffuse gDiffuseMap gVertexColorsEnable gBAT gGlossMap gDarkMap gDetailMap gDecalMap gDark_Amount gDetailAmount gDiffuseMapAmount gNormal_Amount gDecalAmount gDiffuseMapChannel gDarkMapChannel gDecalMapChannel gDetailMapChannel gGlossMapChannel

		m.texmapDiffuse = d
		if(d != undefined) do 
		(
			m.texmapOnDiffuse = on
			if(cbxTexInVieport.checked == true) do	showTextureMap m m.texmapDiffuse true --m.showInViewport = on
		)
		
		
		/*
		--------------------------------------------------------------------------------------
			REFLECTION
		--------------------------------------------------------------------------------------
		*/

		-- Set Reflection Color And Glosiness			
		if(gSpecularEnable != "false" and gReflMap != "false") do
		(
			m.colorReflect = try(gSpecular / 2.0)catch(gSpecular)
			m.reflectGlossiness = 1.0 - (gShininess / 100.0)
			m.levelReflect = 1.0
		)
		
		-- Set Reflection Texture
		m.fresnelIor = 3.0
		r = createReflection gGlossMap gGlossMapChannel gBAT
		m.texmapReflect = r			
		
		if(r != undefined ) do 
		(
			m.texmapOnReflect = on
			m.levelReflect = 0.75
			m.reflectGlossiness = 0.75
		)
		
		if(gReflMap == "false" and r != undefined) do
		(
			m.levelReflect = 0.1
			m.reflectGlossiness = 1.0
		)
					
		/*
		--------------------------------------------------------------------------------------
			REFRACTION
		--------------------------------------------------------------------------------------
		*/
		
		
		-- If used Vertex Color Alpha set as default value 0.5	
		if(gVertexColorsEnable != "false" and gOpacityEnable != "false" and gReflMap != "false") do
		(
			m.levelRefract = 0.95
			try(m.twosidedGlass = on)catch()
		)
		
		-- If used alpha in material set this value
		if(gAlpha != 100.0) do
		(
			--a = (2.55 * gAlpha)
			--m.colorOpacity = color a a a
			
			--a = 1.0 - ((gAlpha / 100.0) / 2.0)
			m.levelRefract = 0.95
			
			try(m.twosidedGlass = on)catch()
		)
		
		-- Set Opacity Texture
		if(gOpacityEnable == "true" and gDiffuseMap != "undefined") do
		(			
			m.texmapOpacity = createBitmap gDiffuseMap gDiffuseMapChannel
			m.colorOpacity = black
			m.texmapOpacity.rgbOutput = 1
			-- Fix opacity in Crorona 1.3
			m.texmapOpacity.monoOutput = 1

			m.texmapOnOpacity = on
		)
		
		/*
		--------------------------------------------------------------------------------------
			NORMAL BUMP
		--------------------------------------------------------------------------------------
		*/
		
		-- Set Normal		
		if(gNormalMap != "undefined") do
		(
			m.texmapOnBump = on
			m.texmapBump = CoronaNormal()			
			m.texmapBump.multiplier = gNormal_Amount * 3
			m.texmapBump.normalMap = createBitmap gNormalMap gNormalMapChannel blurTex: 0.6		
		)
				
		return m
	)
	
	fn importMtl f =
	(
		local mtl = getINISetting f "exportMaterials"
		local sceneName = getINISetting f  "exportScene" "maxFileName"
		local sceneFile = getINISetting f  "exportScene" "maxFilePath"
				
		/*if(sceneName != maxFileName) do
		(
			q = queryBox  "You import materials in to different scenes!\nContinue import?" title: "Warning!"
			if(q == false) do return false
		)*/
		
		if(sceneFile != "undefined") do
		(
			resetMaxFile #noPrompt 
			
			loadMaxFile (sceneFile + sceneName) useFileUnits: true quiet: true
		)
		

		if(isCorona() == false) do 
		(
			q = queryBox "Corona Render is not assigned!\nAssign Corona as current renderer?" title: "Warning!"
			
			if(q == false) do return false
			
			try(renderers.current = CoronaRenderer()) catch
			(
				messageBox "Corona Render not installed!" title: "Warning!"
				return false
			)
		)
		
		for i in geometry where i.material != undefined do i.material.name = stipChars i.material.name
		
		local mtlId = #()
		for i in 1 to mtl.count do mtlId[i] = filterString (getINISetting f "exportMaterials" mtl[i]) ":"
		
		progressStart "Import Materials"
		escapeEnable
			
		for i in 1 to mtl.count do
		(								
			local m
						
			case mtlId[i][1] of
			(
				"0":
				(
					iniMatHeader = mtl[i] + ":0"
					m = createCoronaMtl f iniMatHeader
				)
				default:
				(
					m = multiMaterial()
			
					m.numsubs = 1
					m.name = mtl[i]
						
					
					iCnt = 0
					for ii in mtlId[i] do
					(
						iniMatHeader = mtl[i] + ":" + ii
																
						id = ii as integer
						
						if((hasINISetting f iniMatHeader "id") != true) then
						(
							mm = Standardmaterial()
							mm.name = "NO GB MATERIAL"
						)
						else
						(	
							mm = createCoronaMtl f iniMatHeader																	
						)
						
						iCnt += 1
						m.materialList[iCnt] = mm
						m.materialIDList[iCnt] = id		
					)
				)
			)		
			
			for o in geometry where o.material != undefined and o.material.name == mtl[i] do o.material = m
						
			progressUpdate (100.0 * i / mtl.count)	
						
			if(getProgressCancel() == true) do exit							
		)
		

		lblInfo.caption = sceneName + "\n\nImport materials done."	
		progressEnd()	
	)

	on btnExportImport pressed do
	(
		local f = undefined
				
		if(is2012() == true) then
		(			
			local f = szDefPath
						
			for i in geometry where i.material != undefined do i.material.name = stipChars i.material.name
								
			if(doesFileExist f) do deleteFile f
			
			setINISetting f "exportScene" "maxFilePath" maxFilePath
			setINISetting f "exportScene" "maxFileName" maxFileName
				
			progressStart "Export Materials"
			escapeEnable
				
			for i in 1 to sceneMaterials.count do exportMtl i f	
						
			progressEnd()
						
			sceneName = getINISetting f  "exportScene" "maxFileName"
			lblInfo.caption = sceneName + "\n\nExport scene success."				
		)
		else
		(						
			if(doesFileExist szDefPath != false) then importMtl szDefPath
		)
		
		if(cbxUpdateVC.checked == true) do
		(
			s = selection

			progressStart "Update VertexColor"
			
			g = geometry
			
			o = for i in 1 to g.count do
			(								
				if(classOf g[i].baseObject == Editable_Poly or classOf g[i].baseObject == Editable_Mesh) do
				(
					addModifier g[i] (VertexPaint())
					convertToPoly g[i]
				)
					
				progressUpdate (100.0 * i / g.count)		
			)
			
			progressEnd()	
			
			clearSelection()
						
			clearSelection()	
			select s
		)
	)
	
	on rGB_Corona open do
	(		
		btnExportImport.caption = "Import"
		
		if(is2012() == true) then
		(
			btnExportImport.caption = "Export"
			lblInfo.caption = "Export material in temp file, then import this one in 3D Max with assigned Corona Render."
			cbxTexInVieport.enabled = false
			cbxUpdateVC.enabled = false
			spnDiffuseLevel.enabled = false
			spnRGBLevel.enabled = false
		)   
		else
		(
			if(doesFileExist szDefPath != false) then
			(
				sceneName = getINISetting szDefPath  "exportScene" "maxFileName"
				if(sceneName.count > 0) do lblInfo.caption = "Materials from\n" + sceneName + "\nReady for import."	
			)
			else
			(
				lblInfo.caption = "Please export materials first!"	
			)
		)
	)
)


rollout rAbout "About" 
(	
	label lblName "" 
	label lblVer "" 
	
	label lblAuthor "" height: 30
	label lblCopy ""  height: 30
	button btnHelp "Help" enabled: false
	
	fn getHelp run: false =
	(
		s = getThisScriptFilename()
		i = getScriptInfo s
		szHelp = (getFilenamePath s) + i[7]
		if(i[7] != "" and doesFileExist szHelp) do btnHelp.enabled = true
			
		if(run) do ShellLaunch szHelp ""
	)
	
	on btnHelp pressed do getHelp run: true
				
	on rAbout open do
	(		
		i = getScriptInfo (getThisScriptFilename())
			
		lblName.caption = i[1]
		lblAuthor.caption = i[2]
		lblVer.caption = i[3]
		lblCopy.caption = i[6]
		
		getHelp()
	)
)

addRollout rGB_Corona rGamebryoToCorona rolledUp:false 
addRollout rAbout rGamebryoToCorona rolledUp:true 












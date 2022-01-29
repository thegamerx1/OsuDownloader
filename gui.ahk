class MyGui {
	init(links) {
		this.links := links
		this.gui := new EzGui(this, {title: "Osu! Downloader", w:500, h:300})
		this.gui.inithooks()
		this.total := this.links.length()
		this.gui.get("ProgressText").set("0/" this.total)
		this.gui.visible := true
		this.loopy()
	}

	buildGui(g) {
		g.add("Progress", "vProgress x0 y0 yp w500 h30 Background878787", "100")
		Gui Font, s13 cFFFFFF
		g.add("Text", "vProgressText x0 y4 w500 +Center +BackgroundTrans")
		g.resetFont()

		Gui Font, s11 cFFFFFF
		g.add("Text", "vCurrent x0 w500 +Center", "Current: ")
		g.add("Text", "vSpeed x0 w500 +Center", "...")
		g.resetFont()

		Gui Font, s10 c32cd32 q5, Consolas
		Gui Font,, Fira Code
		Gui Color, 1d1f21, 282a2e
		hwnd := g.add("Edit", "xm vConsoleEdit ReadOnly +0x840 -E0x200 y+10 w480 h200").hwnd
		Debug.attachEdit := hwnd
	}

	loopy() {
		link := this.links.pop()
		if (!link) {
			debug.print("done")
			return
		}
		link := StrReplace(link, "/download", "")

		; ? For shortened urls
		if !InStr(link, "beatmapsets") {
			http := new requests(link, "GET")
			data := http.send()
			if (data.status !== 302) {
				Debug.print("Error")
				return
			}
			link := data.headers["Location"]
		}
		link := RegExReplace(link, "#osu\/\d+", "") "/download"

		http := new requests("GET", link)
		http.cookies["osu_session"] := progConfig.data.session
		http.headers["Referer"] := "https://osu.ppy.sh/"
		data := http.send()
		url := data.headers["Location"]
		objUrl := urlCode.url(url)

		if (data.status == 302 && objurl.params.fs) {
			this.gui.get("Current").set("Current: " objUrl.params.fs)
			file := new FileDownloader(url, progConfig.data.path objUrl.params.fs, ObjBindMethod(this, "progress"))
		} else {
			debug.print("error :(")
			return
		}
	}

	progress(percent, speed) {
		local func
		switch (percent) {
			case -1:
				debug.print("Size: " speed "MiB")
			case 100:
				this.gui.get("progress").set(100)
				this.gui.get("ProgressText").set(this.total - this.links.length() "/" this.total)
				func := ObjBindMethod(this, "loopy")
				SetTimer % func, -1000
			default:
				this.gui.get("progress").set(percent)
				this.gui.get("speed").set(speed)
		}
	}
}

class loginGui {
	init() {
		this.gui := new EzGui(this, {title: "Osu! Downloader", AutoSize: true})
		this.gui.inithooks()
		this.gui.visible := true
	}

	buildGui(g) {
		g.add("text",, "Osu session cookie")
		g.add("Edit", "vsession w320 r1 Password", progConfig.data.session)
		g.add("text",, "Download links")
		g.add("Edit", "vlinks w320 r15")
		g.add("Button", "vSubmit w320 h30", "Login").on("submit")
	}

	submit(e) {
		this.session := this.gui.get("session").get()

		e.set("Loading..").disable()
		this.gui.get("links").disable()
		this.gui.get("session").disable()

		http := new requests("GET", "https://osu.ppy.sh/notifications/endpoint",, true)
		http.cookies["osu_session"] := this.session

		http.onFinished := ObjBindMethod(this, "request", e)
		http.send()
	}

	request(e, http) {
		failed := false
		links := this.gui.get("links").get()
		if !links {
			msgbox links?
			failed := true
		}

		if (http.status != 200 || failed) {
			e.set("Login failed").enable().option()
			this.gui.get("links").enable()
			this.gui.get("session").enable()
			return
		}

		links := SplitLine(Trim(links, " `n`t`r"))

		if !progConfig.data.session
			Msgbox Your session cookie will be stored on settings.json

		progConfig.data.session := this.session
		progConfig.save()
		this.gui.visible := false
		MyGui.init(links)
	}
}
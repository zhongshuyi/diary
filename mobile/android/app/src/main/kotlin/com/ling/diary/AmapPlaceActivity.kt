package com.ling.diary

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.graphics.Color
import android.graphics.Bitmap
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.net.Uri
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.BaseAdapter
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import android.widget.Toast
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import com.amap.api.maps.AMap
import com.amap.api.maps.CameraUpdateFactory
import com.amap.api.maps.MapView
import com.amap.api.maps.MapsInitializer
import com.amap.api.maps.model.CameraPosition
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.MarkerOptions
import com.amap.api.maps.model.BitmapDescriptorFactory
import com.amap.api.services.core.LatLonPoint
import com.amap.api.services.core.PoiItem
import com.amap.api.services.core.ServiceSettings
import com.amap.api.services.geocoder.GeocodeResult
import com.amap.api.services.geocoder.GeocodeSearch
import com.amap.api.services.geocoder.RegeocodeQuery
import com.amap.api.services.geocoder.RegeocodeResult
import com.amap.api.services.poisearch.PoiResult
import com.amap.api.services.poisearch.PoiSearch
import kotlin.math.abs
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

class AmapPlaceActivity : Activity(), AMap.OnCameraChangeListener,
    GeocodeSearch.OnGeocodeSearchListener, PoiSearch.OnPoiSearchListener {

    private data class Place(val name: String, val address: String, val latitude: Double, val longitude: Double)

    private lateinit var mapView: MapView
    private lateinit var map: AMap
    private lateinit var placesList: ListView
    private lateinit var placesAdapter: BaseAdapter
    private lateinit var status: TextView
    private lateinit var searchField: EditText
    private var selectedName: TextView? = null
    private var selectedAddress: TextView? = null
    private var sendButton: TextView? = null
    private var centerPin: ImageView? = null
    private var locationHint: TextView? = null
    private var locationClient: AMapLocationClient? = null
    private var geocoder: GeocodeSearch? = null
    private var selected: Place? = null
    private var places = listOf<Place>()
    private var ignoreCameraChange = false
    private var selectionFromCamera = false
    private var resolvingCamera = false
    private var pinRaised = false
    private var userInteracted = false
    private var mapGesture = false
    private var viewOnly = false

    private var ink = 0xFF24231F.toInt()
    private var muted = 0xFF81776D.toInt()
    private var paper = 0xFFF7F3EC.toInt()
    private var surface = 0xFFFFFCF7.toInt()
    private var line = 0xFFE6DED2.toInt()
    private var accent = 0xFFB55C44.toInt()
    private var accentSoft = 0xFFF1D8CE.toInt()
    private var onAccent = Color.WHITE
    private var darkTheme = false
    private var sendingPlace = false

    override fun onCreate(savedInstanceState: Bundle?) {
        darkTheme = intent.getBooleanExtra("darkTheme", false)
        if (darkTheme) setTheme(R.style.AmapPlaceDarkTheme)
        super.onCreate(savedInstanceState)
        paper = intent.getIntExtra("paperColor", paper)
        surface = intent.getIntExtra("surfaceColor", surface)
        ink = intent.getIntExtra("inkColor", ink)
        muted = intent.getIntExtra("mutedColor", muted)
        line = intent.getIntExtra("lineColor", line)
        accent = intent.getIntExtra("accentColor", accent)
        accentSoft = intent.getIntExtra("accentSoftColor", accentSoft)
        onAccent = intent.getIntExtra("onAccentColor", onAccent)
        val key = intent.getStringExtra("key").orEmpty()
        if (key.isBlank()) {
            finish()
            return
        }
        viewOnly = intent.getBooleanExtra("viewOnly", false)
        try {
            MapsInitializer.updatePrivacyShow(this, true, true)
            MapsInitializer.updatePrivacyAgree(this, true)
            AMapLocationClient.updatePrivacyShow(this, true, true)
            AMapLocationClient.updatePrivacyAgree(this, true)
            ServiceSettings.updatePrivacyShow(this, true, true)
            ServiceSettings.updatePrivacyAgree(this, true)
            MapsInitializer.setApiKey(key)
            AMapLocationClient.setApiKey(key)
            ServiceSettings.getInstance().setApiKey(key)
            buildScreen(savedInstanceState)
            geocoder = GeocodeSearch(this).also { it.setOnGeocodeSearchListener(this) }
        } catch (error: Exception) {
            Toast.makeText(this, "高德地图初始化失败：${error.message.orEmpty()}", Toast.LENGTH_LONG).show()
            finish()
            return
        }

        if (viewOnly && intent.hasExtra("latitude") && intent.hasExtra("longitude")) {
            val latitude = intent.getDoubleExtra("latitude", 0.0)
            val longitude = intent.getDoubleExtra("longitude", 0.0)
            selected = Place(intent.getStringExtra("name").orEmpty(),
                intent.getStringExtra("address").orEmpty(), latitude, longitude)
            ignoreCameraChange = true
            map.moveCamera(CameraUpdateFactory.newLatLngZoom(LatLng(latitude, longitude), 16f))
            map.addMarker(MarkerOptions().position(LatLng(latitude, longitude))
                .title(selected?.name).snippet(selected?.address))
            renderPlaces(listOfNotNull(selected))
        } else {
            requestCurrentLocation()
        }
    }

    private fun buildScreen(savedInstanceState: Bundle?) {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(paper)
            if (Build.VERSION.SDK_INT >= 35) {
                setOnApplyWindowInsetsListener { view, insets ->
                    val bars = insets.getInsets(WindowInsets.Type.systemBars())
                    view.setPadding(0, bars.top, 0, bars.bottom)
                    insets
                }
            }
        }
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(16), dp(7), dp(16), dp(7))
        }
        val back = actionLabel("‹  返回", false).apply {
            contentDescription = "返回对话"
            setOnClickListener { finish() }
        }
        header.addView(back, LinearLayout.LayoutParams(dp(76), dp(42)))
        header.addView(TextView(this).apply {
            text = if (viewOnly) "位置详情" else "选择位置"
            textSize = 18f
            setTextColor(ink)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }, LinearLayout.LayoutParams(0, dp(48), 1f))
        header.addView(View(this), LinearLayout.LayoutParams(dp(76), dp(42)))
        root.addView(header)

        if (!viewOnly) {
            val searchRow = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(dp(12), 0, dp(5), 0)
                background = rounded(surface, 16, line)
            }
            searchRow.addView(TextView(this).apply {
                text = "⌕"
                textSize = 29f
                gravity = Gravity.CENTER
                setTextColor(muted)
            }, LinearLayout.LayoutParams(dp(30), dp(44)))
            searchField = EditText(this).apply {
                hint = "搜索地点、地址"
                textSize = 15f
                setTextColor(ink)
                setHintTextColor(muted)
                background = null
                setSingleLine(true)
                imeOptions = EditorInfo.IME_ACTION_SEARCH
                setOnEditorActionListener { _, _, _ -> searchPlaces(); true }
            }
            searchRow.addView(searchField, LinearLayout.LayoutParams(0, dp(52), 1f))
            searchRow.addView(actionLabel("搜索", true).apply {
                setOnClickListener { searchPlaces() }
            }, LinearLayout.LayoutParams(dp(66), dp(38)))
            root.addView(searchRow, LinearLayout.LayoutParams(-1, dp(52)).apply {
                setMargins(dp(16), dp(2), dp(16), dp(12))
            })
        }

        val mapFrame = FrameLayout(this).apply {
            background = rounded(surface, 20)
            clipToOutline = true
            elevation = dp(2).toFloat()
        }
        mapView = MapView(this).apply { onCreate(savedInstanceState) }
        mapFrame.addView(mapView, FrameLayout.LayoutParams(-1, -1))
        if (!viewOnly) {
            locationHint = TextView(this).apply {
                text = "正在定位当前位置…"
                textSize = 13f
                setTextColor(ink)
                setPadding(dp(12), dp(8), dp(12), dp(8))
                background = rounded(surface, 12, line)
                elevation = dp(3).toFloat()
            }
            mapFrame.addView(locationHint, FrameLayout.LayoutParams(-2, -2,
                Gravity.START or Gravity.TOP).apply { setMargins(dp(12), dp(12), 0, 0) })
            centerPin = ImageView(this).apply {
                setImageResource(android.R.drawable.ic_menu_mylocation)
                setColorFilter(accent)
                contentDescription = "地图中心选点"
                elevation = dp(5).toFloat()
            }
            mapFrame.addView(centerPin, FrameLayout.LayoutParams(dp(36), dp(36), Gravity.CENTER))
            mapFrame.addView(actionLabel("◎  定位", false).apply {
                elevation = dp(4).toFloat()
                contentDescription = "重新定位当前位置"
                setOnClickListener { requestCurrentLocation() }
            }, FrameLayout.LayoutParams(dp(92), dp(42), Gravity.END or Gravity.BOTTOM).apply {
                setMargins(0, 0, dp(12), dp(12))
            })
        }
        root.addView(mapFrame, LinearLayout.LayoutParams(-1,
            (resources.displayMetrics.heightPixels * .40).toInt()).apply {
            setMargins(dp(16), 0, dp(16), dp(10))
        })
        map = mapView.map
        map.mapType = if (darkTheme) AMap.MAP_TYPE_NIGHT else AMap.MAP_TYPE_NORMAL
        map.uiSettings.isZoomControlsEnabled = false
        map.setOnMapTouchListener { event ->
            if (event.actionMasked == MotionEvent.ACTION_DOWN) mapGesture = true
        }
        if (!viewOnly) map.setOnCameraChangeListener(this)

        status = TextView(this).apply {
            text = if (viewOnly) "已保存的位置" else "正在获取当前位置…"
            setTextColor(muted)
            setPadding(dp(2), dp(7), dp(2), dp(9))
            textSize = 14f
        }
        root.addView(status, LinearLayout.LayoutParams(-1, dp(38)).apply {
            setMargins(dp(16), 0, dp(16), 0)
        })
        placesList = ListView(this).apply {
            setOnItemClickListener { _, _, position, _ -> choosePlace(position) }
            divider = null
            setBackgroundColor(Color.TRANSPARENT)
            clipToPadding = false
            setPadding(0, 0, 0, dp(8))
        }
        placesAdapter = createPlacesAdapter()
        placesList.adapter = placesAdapter
        root.addView(placesList, LinearLayout.LayoutParams(-1, 0, 1f).apply {
            setMargins(dp(16), 0, dp(16), 0)
        })

        val bottom = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(18), dp(12), dp(16), dp(12))
            background = rounded(surface, 20, line)
        }
        val summary = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        selectedName = TextView(this).apply {
            text = if (viewOnly) "已保存的位置" else "选择一个地点"
            textSize = 15f
            setTextColor(ink)
            typeface = Typeface.DEFAULT_BOLD
            maxLines = 1
            ellipsize = android.text.TextUtils.TruncateAt.END
        }
        selectedAddress = TextView(this).apply {
            text = if (viewOnly) "" else "拖动地图或搜索地点"
            textSize = 12f
            setTextColor(muted)
            maxLines = 1
            ellipsize = android.text.TextUtils.TruncateAt.END
        }
        summary.addView(selectedName)
        summary.addView(selectedAddress)
        bottom.addView(summary, LinearLayout.LayoutParams(0, -2, 1f))
        sendButton = actionLabel(when {
            viewOnly -> "高德打开"
            intent.getBooleanExtra("includeThumbnail", true) -> "发送位置"
            else -> "确定地点"
        }, true).apply {
            isEnabled = viewOnly
            alpha = if (viewOnly) 1f else .45f
            setOnClickListener { if (viewOnly) openAmapApp() else sendSelected() }
        }
        bottom.addView(sendButton, LinearLayout.LayoutParams(dp(108), dp(46)).apply {
            marginStart = dp(12)
        })
        root.addView(bottom, LinearLayout.LayoutParams(-1, dp(78)).apply {
            setMargins(dp(16), dp(4), dp(16), dp(12))
        })
        setContentView(root)
        if (Build.VERSION.SDK_INT >= 30) {
            val lightBars = WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or
                WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
            window.insetsController?.setSystemBarsAppearance(
                if (darkTheme) 0 else lightBars, lightBars)
        }
        @Suppress("DEPRECATION")
        window.statusBarColor = paper
        @Suppress("DEPRECATION")
        window.navigationBarColor = paper
    }

    private fun requestCurrentLocation() {
        userInteracted = false
        locationHint?.apply { text = "正在定位当前位置…"; alpha = 1f; visibility = View.VISIBLE }
        setStatus("正在获取当前位置…")
        if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION), 91)
            return
        }
        try {
            locationClient?.onDestroy()
            locationClient = AMapLocationClient(applicationContext).also { client ->
                client.setLocationOption(AMapLocationClientOption().apply {
                    isOnceLocation = true
                    isNeedAddress = true
                    httpTimeOut = 20000
                })
                client.setLocationListener { location ->
                    if (userInteracted) return@setLocationListener
                    if (location == null || location.errorCode != 0) {
                        locationHint?.text = "定位暂不可用，可拖动地图"
                        setStatus("定位失败（${location?.errorCode ?: "未知"}），可拖动地图或搜索地点")
                        return@setLocationListener
                    }
                    val point = LatLng(location.latitude, location.longitude)
                    selectionFromCamera = false
                    resolvingCamera = false
                    val localName = location.poiName?.takeIf { it.isNotBlank() }
                    val address = listOfNotNull(localName, location.address?.takeIf { it.isNotBlank() })
                        .distinct().joinToString(" · ")
                    selected = Place(localName ?: "当前位置", address, point.latitude, point.longitude)
                    ignoreCameraChange = true
                    map.moveCamera(CameraUpdateFactory.newLatLngZoom(point, 16f))
                    map.clear()
                    map.addMarker(MarkerOptions().position(point).title(selected?.name)
                        .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_AZURE)))
                    renderPlaces(listOfNotNull(selected))
                    setStatus("当前位置已找到，可继续选择附近地点")
                    locationHint?.animate()?.alpha(0f)?.setDuration(220)?.withEndAction {
                        locationHint?.visibility = View.GONE
                    }?.start()
                    reverseGeocode(point)
                }
                client.startLocation()
            }
        } catch (error: Exception) {
            locationHint?.text = "定位暂不可用，可拖动地图"
            setStatus("定位无法启动，可拖动地图或搜索地点")
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != 91) return
        if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) requestCurrentLocation()
        else {
            locationHint?.text = "未获得定位权限，可拖动地图"
            setStatus("未获得定位权限，可拖动地图或搜索地点")
        }
    }

    override fun onCameraChange(position: CameraPosition?) {
        if (!viewOnly && mapGesture && !ignoreCameraChange && !pinRaised) {
            pinRaised = true
            centerPin?.animate()?.translationY(-dp(7).toFloat())?.setDuration(120)?.start()
        }
    }

    override fun onCameraChangeFinish(position: CameraPosition?) {
        if (viewOnly || position == null) return
        if (ignoreCameraChange) {
            ignoreCameraChange = false
            mapGesture = false
            pinRaised = false
            centerPin?.animate()?.translationY(0f)?.setDuration(180)?.start()
            return
        }
        if (!mapGesture) return
        mapGesture = false
        locationHint?.visibility = View.GONE
        pinRaised = false
        centerPin?.animate()?.translationY(0f)?.setDuration(220)?.start()
        userInteracted = true
        selectionFromCamera = true
        resolvingCamera = true
        selected = Place("${position.target.latitude}, ${position.target.longitude}", "",
            position.target.latitude, position.target.longitude)
        renderPlaces(listOfNotNull(selected))
        setStatus("正在查找附近地点…")
        reverseGeocode(position.target)
    }

    private fun reverseGeocode(point: LatLng) {
        geocoder?.getFromLocationAsyn(RegeocodeQuery(
            LatLonPoint(point.latitude, point.longitude), 500f, GeocodeSearch.AMAP))
    }

    override fun onRegeocodeSearched(result: RegeocodeResult?, code: Int) {
        if (viewOnly) return
        val point = result?.regeocodeQuery?.point ?: run {
            if (resolvingCamera) {
                resolvingCamera = false
                renderPlaces(listOfNotNull(selected))
                setStatus("附近地点不可用，可搜索地点")
            }
            return
        }
        val center = map.cameraPosition.target
        if (abs(point.latitude - center.latitude) > .0001 ||
            abs(point.longitude - center.longitude) > .0001) return
        if (code != 1000 || result.regeocodeAddress == null) {
            resolvingCamera = false
            renderPlaces(listOfNotNull(selected))
            setStatus("附近地点不可用，可搜索地点")
            return
        }
        val address = result.regeocodeAddress
        val nearby = mutableListOf(Place(
            address.aois?.firstOrNull()?.aoiName?.takeIf { it.isNotBlank() }
                ?: address.pois?.firstOrNull()?.title?.takeIf { it.isNotBlank() }
                ?: address.formatAddress?.takeIf { it.isNotBlank() }
                ?: "${point.latitude}, ${point.longitude}",
            address.formatAddress.orEmpty(), point.latitude, point.longitude))
        nearby += address.pois.orEmpty().mapNotNull(::placeFromPoi)
        resolvingCamera = false
        if (selectionFromCamera || selected?.name == "当前位置") selected = nearby.first()
        renderPlaces(if (selectionFromCamera) nearby else listOfNotNull(selected) + nearby)
        setStatus(if (selectionFromCamera) "已定位到地图中心，选择附近地点" else "当前位置附近的地点")
    }

    override fun onGeocodeSearched(result: GeocodeResult?, code: Int) = Unit

    private fun searchPlaces() {
        val keyword = searchField.text.toString().trim()
        userInteracted = true
        locationHint?.visibility = View.GONE
        (getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager)
            .hideSoftInputFromWindow(searchField.windowToken, 0)
        searchField.clearFocus()
        if (keyword.isEmpty()) {
            setStatus("正在查找附近地点…")
            reverseGeocode(map.cameraPosition.target)
            return
        }
        setStatus("正在搜索地点…")
        try {
            PoiSearch(this, PoiSearch.Query(keyword, "", "").apply { pageSize = 20 }).also {
                it.setOnPoiSearchListener(this)
                it.searchPOIAsyn()
            }
        } catch (error: Exception) {
            setStatus("搜索失败，请重试")
        }
    }

    override fun onPoiSearched(result: PoiResult?, code: Int) {
        if (code != 1000 || result == null) {
            setStatus("搜索失败，请重试")
            return
        }
        val found = result.pois.orEmpty().mapNotNull(::placeFromPoi)
        if (found.isEmpty()) {
            renderPlaces(emptyList())
            setStatus("没有找到相关地点")
            return
        }
        selectionFromCamera = false
        resolvingCamera = false
        selected = found.first()
        renderPlaces(found)
        setStatus("搜索结果 · 已选中第一项")
        ignoreCameraChange = true
        map.animateCamera(CameraUpdateFactory.newLatLngZoom(
            LatLng(found.first().latitude, found.first().longitude), 16f))
    }

    override fun onPoiItemSearched(item: PoiItem?, code: Int) = Unit

    private fun placeFromPoi(item: PoiItem): Place? {
        val point = item.latLonPoint ?: return null
        return Place(item.title?.takeIf { it.isNotBlank() }
            ?: item.snippet?.takeIf { it.isNotBlank() }
            ?: "${point.latitude}, ${point.longitude}", item.snippet.orEmpty(),
            point.latitude, point.longitude)
    }

    private fun renderPlaces(items: List<Place>) {
        places = items
        selectedName?.text = selected?.name ?: "选择一个地点"
        selectedAddress?.text = selected?.address?.takeIf { it.isNotBlank() }
            ?: if (selected == null) "拖动地图或搜索地点" else "可在地图上调整位置"
        sendButton?.let { button ->
            button.isEnabled = selected != null && !resolvingCamera
            button.animate().alpha(if (button.isEnabled) 1f else .45f).setDuration(180).start()
        }
        placesAdapter.notifyDataSetChanged()
    }

    private fun createPlacesAdapter(): BaseAdapter = object : BaseAdapter() {
            override fun getCount(): Int = places.size
            override fun getItem(position: Int): Place? = places.getOrNull(position)
            override fun getItemId(position: Int): Long = position.toLong()
            override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                val place = getItem(position) ?: return View(this@AmapPlaceActivity)
                val active = place == selected
                val row = LinearLayout(this@AmapPlaceActivity).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    setPadding(dp(14), dp(10), dp(12), dp(10))
                    background = rounded(if (active) accentSoft else surface,
                        14, if (active) accent else line)
                }
                row.addView(TextView(this@AmapPlaceActivity).apply {
                    text = if (active) "●" else "○"
                    textSize = 18f
                    setTextColor(accent)
                    gravity = Gravity.CENTER
                }, LinearLayout.LayoutParams(dp(28), dp(36)))
                val details = LinearLayout(this@AmapPlaceActivity).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(dp(8), 0, 0, 0)
                }
                details.addView(TextView(this@AmapPlaceActivity).apply {
                    text = place.name
                    textSize = 15f
                    typeface = if (active) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
                    setTextColor(ink)
                    maxLines = 1
                    ellipsize = android.text.TextUtils.TruncateAt.END
                })
                if (place.address.isNotBlank()) details.addView(TextView(this@AmapPlaceActivity).apply {
                    text = place.address
                    textSize = 12f
                    setTextColor(muted)
                    maxLines = 1
                    ellipsize = android.text.TextUtils.TruncateAt.END
                })
                row.addView(details, LinearLayout.LayoutParams(0, -2, 1f))
                row.contentDescription = listOf(place.name, place.address)
                    .filter { it.isNotBlank() }.joinToString("，")
                return LinearLayout(this@AmapPlaceActivity).apply {
                    setPadding(0, 0, 0, dp(7))
                    addView(row, LinearLayout.LayoutParams(-1, dp(62)))
                }
            }
        }

    private fun choosePlace(position: Int) {
        val place = places.getOrNull(position) ?: return
        if (viewOnly) return
        userInteracted = true
        selectionFromCamera = false
        resolvingCamera = false
        selected = place
        renderPlaces(places)
        setStatus("已选择：${place.name}")
        ignoreCameraChange = true
        map.animateCamera(CameraUpdateFactory.newLatLngZoom(
            LatLng(place.latitude, place.longitude), 16f))
    }

    private fun sendSelected() {
        val place = selected ?: run {
            Toast.makeText(this, "请先选择一个地点", Toast.LENGTH_SHORT).show()
            return
        }
        if (sendingPlace || resolvingCamera) return
        if (!intent.getBooleanExtra("includeThumbnail", true)) {
            finishWithPlace(place, null)
            return
        }
        sendingPlace = true
        sendButton?.isEnabled = false
        sendButton?.alpha = .45f
        setStatus("正在生成地图预览…")
        ignoreCameraChange = true
        map.moveCamera(CameraUpdateFactory.newLatLngZoom(
            LatLng(place.latitude, place.longitude), 16f))
        val handler = Handler(Looper.getMainLooper())
        var captured = false
        val timeout = Runnable {
            if (!captured) {
                captured = true
                finishWithPlace(place, null)
            }
        }
        handler.postDelayed(timeout, 2000)
        mapView.postDelayed({
            if (captured || isFinishing) return@postDelayed
            try {
                map.getMapScreenShot(object : AMap.OnMapScreenShotListener {
                    override fun onMapScreenShot(bitmap: Bitmap?) {
                        if (captured || bitmap == null) return
                        captured = true
                        handler.removeCallbacks(timeout)
                        Thread {
                            val path = try { writeMapPreview(bitmap) } catch (_: Exception) { null }
                            runOnUiThread { if (!isFinishing) finishWithPlace(place, path) }
                        }.start()
                    }

                    override fun onMapScreenShot(bitmap: Bitmap?, status: Int) {
                        onMapScreenShot(bitmap)
                    }
                })
            } catch (_: Exception) {
                if (!captured) {
                    captured = true
                    handler.removeCallbacks(timeout)
                    finishWithPlace(place, null)
                }
            }
        }, 180)
    }

    private fun writeMapPreview(bitmap: Bitmap): String? {
        if (bitmap.width <= 0 || bitmap.height <= 0) return null
        val cropHeight = minOf(bitmap.height, bitmap.width / 2)
        val cropped = Bitmap.createBitmap(bitmap, 0, (bitmap.height - cropHeight) / 2,
            bitmap.width, cropHeight)
        var scaled: Bitmap? = null
        try {
            val preview = Bitmap.createScaledBitmap(cropped, 560, 280, true)
            scaled = preview
            val directory = File(filesDir, "location_previews")
            if (!directory.isDirectory && !directory.mkdirs()) return null
            val file = File(directory, "${UUID.randomUUID()}.jpg")
            FileOutputStream(file).use { output ->
                if (!preview.compress(Bitmap.CompressFormat.JPEG, 82, output)) return null
            }
            return file.absolutePath
        } finally {
            if (scaled !== bitmap) scaled?.recycle()
            if (cropped !== bitmap && cropped !== scaled) cropped.recycle()
        }
    }

    private fun finishWithPlace(place: Place, thumbnailPath: String?) {
        setResult(RESULT_OK, Intent().apply {
            putExtra("name", place.name)
            putExtra("address", place.address)
            putExtra("latitude", place.latitude)
            putExtra("longitude", place.longitude)
            putExtra("thumbnailPath", thumbnailPath)
        })
        finish()
    }

    private fun setStatus(message: String) {
        if (!::status.isInitialized || status.text == message) return
        status.animate().cancel()
        status.alpha = .45f
        status.text = message
        status.animate().alpha(1f).setDuration(180).start()
    }

    private fun rounded(color: Int, radius: Int, stroke: Int? = null): GradientDrawable =
        GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(radius).toFloat()
            if (stroke != null) setStroke(dp(1), stroke)
        }

    private fun actionLabel(label: String, filled: Boolean): TextView = TextView(this).apply {
        text = label
        textSize = 14f
        typeface = Typeface.DEFAULT_BOLD
        gravity = Gravity.CENTER
        setTextColor(if (filled) onAccent else accent)
        background = rounded(if (filled) accent else surface, 13,
            if (filled) null else line)
    }

    private fun openAmapApp() {
        val place = selected ?: return
        val uri = Uri.Builder().scheme("androidamap").authority("viewMap")
            .appendQueryParameter("sourceApplication", "此刻")
            .appendQueryParameter("poiname", place.name)
            .appendQueryParameter("lat", place.latitude.toString())
            .appendQueryParameter("lon", place.longitude.toString())
            .appendQueryParameter("dev", "0")
            .build()
        try {
            startActivity(Intent(Intent.ACTION_VIEW, uri).setPackage("com.autonavi.minimap"))
        } catch (_: ActivityNotFoundException) {
            Toast.makeText(this, "未安装高德地图，可在此页查看位置", Toast.LENGTH_SHORT).show()
        }
    }

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()

    override fun onResume() { super.onResume(); if (::mapView.isInitialized) mapView.onResume() }
    override fun onPause() { if (::mapView.isInitialized) mapView.onPause(); super.onPause() }
    override fun onSaveInstanceState(outState: Bundle) {
        if (::mapView.isInitialized) mapView.onSaveInstanceState(outState)
        super.onSaveInstanceState(outState)
    }
    override fun onDestroy() {
        locationClient?.stopLocation()
        locationClient?.onDestroy()
        if (::mapView.isInitialized) mapView.onDestroy()
        super.onDestroy()
    }
}

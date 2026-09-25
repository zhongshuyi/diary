package com.ling.diary

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.net.Uri
import android.view.Gravity
import android.view.inputmethod.EditorInfo
import android.widget.ArrayAdapter
import android.widget.Button
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

class AmapPlaceActivity : Activity(), AMap.OnCameraChangeListener,
    GeocodeSearch.OnGeocodeSearchListener, PoiSearch.OnPoiSearchListener {

    private data class Place(val name: String, val address: String, val latitude: Double, val longitude: Double)

    private lateinit var mapView: MapView
    private lateinit var map: AMap
    private lateinit var placesList: ListView
    private lateinit var status: TextView
    private lateinit var searchField: EditText
    private var locationClient: AMapLocationClient? = null
    private var geocoder: GeocodeSearch? = null
    private var selected: Place? = null
    private var places = listOf<Place>()
    private var ignoreCameraChange = false
    private var viewOnly = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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
            setBackgroundColor(0xFFF8F6F1.toInt())
        }
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(12), 0, dp(16), 0)
        }
        val back = Button(this).apply {
            text = "返回"
            setOnClickListener { finish() }
        }
        header.addView(back)
        header.addView(TextView(this).apply {
            text = if (viewOnly) "位置详情" else "选择位置"
            textSize = 18f
            gravity = Gravity.CENTER
        }, LinearLayout.LayoutParams(0, dp(52), 1f))
        if (!viewOnly) {
            header.addView(Button(this).apply {
                text = "发送"
                setOnClickListener { sendSelected() }
            })
        } else {
            header.addView(Button(this).apply {
                text = "高德打开"
                setOnClickListener { openAmapApp() }
            })
        }
        root.addView(header)

        if (!viewOnly) {
            val searchRow = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                setPadding(dp(12), 0, dp(12), dp(6))
            }
            searchField = EditText(this).apply {
                hint = "搜索地点"
                setSingleLine(true)
                imeOptions = EditorInfo.IME_ACTION_SEARCH
                setOnEditorActionListener { _, _, _ -> searchPlaces(); true }
            }
            searchRow.addView(searchField, LinearLayout.LayoutParams(0, dp(50), 1f))
            searchRow.addView(Button(this).apply {
                text = "搜索"
                setOnClickListener { searchPlaces() }
            })
            root.addView(searchRow)
        }

        val mapFrame = FrameLayout(this)
        mapView = MapView(this).apply { onCreate(savedInstanceState) }
        mapFrame.addView(mapView, FrameLayout.LayoutParams(-1, -1))
        if (!viewOnly) {
            mapFrame.addView(ImageView(this).apply {
                setImageResource(android.R.drawable.ic_menu_mylocation)
            }, FrameLayout.LayoutParams(dp(32), dp(32), Gravity.CENTER))
            mapFrame.addView(Button(this).apply {
                text = "定位"
                setOnClickListener { requestCurrentLocation() }
            }, FrameLayout.LayoutParams(dp(76), dp(48), Gravity.END or Gravity.BOTTOM).apply {
                setMargins(0, 0, dp(10), dp(10))
            })
        }
        root.addView(mapFrame, LinearLayout.LayoutParams(-1,
            (resources.displayMetrics.heightPixels * .38).toInt()))
        map = mapView.map
        map.uiSettings.isZoomControlsEnabled = false
        map.moveCamera(CameraUpdateFactory.newLatLngZoom(LatLng(35.0, 104.0), 4f))
        if (!viewOnly) map.setOnCameraChangeListener(this)

        status = TextView(this).apply {
            text = if (viewOnly) "已保存的位置" else "正在获取当前位置…"
            setPadding(dp(16), dp(12), dp(16), dp(8))
            textSize = 14f
        }
        root.addView(status)
        placesList = ListView(this).apply {
            setOnItemClickListener { _, _, position, _ -> choosePlace(position) }
        }
        root.addView(placesList, LinearLayout.LayoutParams(-1, 0, 1f))
        setContentView(root)
    }

    private fun requestCurrentLocation() {
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
                    if (location == null || location.errorCode != 0) {
                        status.text = "定位失败，可拖动地图或搜索地点"
                        return@setLocationListener
                    }
                    val point = LatLng(location.latitude, location.longitude)
                    selected = Place(location.poiName?.takeIf { it.isNotBlank() }
                        ?: location.district?.takeIf { it.isNotBlank() } ?: "当前位置",
                        location.address.orEmpty(), point.latitude, point.longitude)
                    ignoreCameraChange = true
                    map.moveCamera(CameraUpdateFactory.newLatLngZoom(point, 16f))
                    renderPlaces(listOfNotNull(selected))
                    reverseGeocode(point)
                }
                client.startLocation()
            }
        } catch (error: Exception) {
            status.text = "定位无法启动，可拖动地图或搜索地点"
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != 91) return
        if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) requestCurrentLocation()
        else status.text = "未获得定位权限，可拖动地图或搜索地点"
    }

    override fun onCameraChange(position: CameraPosition?) = Unit

    override fun onCameraChangeFinish(position: CameraPosition?) {
        if (viewOnly || position == null) return
        if (ignoreCameraChange) {
            ignoreCameraChange = false
            return
        }
        selected = Place("地图中心位置", "", position.target.latitude, position.target.longitude)
        renderPlaces(listOfNotNull(selected))
        status.text = "正在查找附近地点…"
        reverseGeocode(position.target)
    }

    private fun reverseGeocode(point: LatLng) {
        geocoder?.getFromLocationAsyn(RegeocodeQuery(
            LatLonPoint(point.latitude, point.longitude), 500f, GeocodeSearch.AMAP))
    }

    override fun onRegeocodeSearched(result: RegeocodeResult?, code: Int) {
        if (viewOnly) return
        val point = result?.regeocodeQuery?.point ?: return
        val center = map.cameraPosition.target
        if (abs(point.latitude - center.latitude) > .0001 ||
            abs(point.longitude - center.longitude) > .0001) return
        if (code != 1000 || result.regeocodeAddress == null) {
            status.text = "附近地点不可用，可搜索地点"
            return
        }
        val address = result.regeocodeAddress
        val nearby = mutableListOf(Place(
            address.aois?.firstOrNull()?.aoiName ?: "地图中心位置",
            address.formatAddress.orEmpty(), point.latitude, point.longitude))
        nearby += address.pois.orEmpty().mapNotNull(::placeFromPoi)
        renderPlaces(nearby)
        if (selected == null) selected = nearby.first()
    }

    override fun onGeocodeSearched(result: GeocodeResult?, code: Int) = Unit

    private fun searchPlaces() {
        val keyword = searchField.text.toString().trim()
        if (keyword.isEmpty()) {
            reverseGeocode(map.cameraPosition.target)
            return
        }
        status.text = "正在搜索地点…"
        try {
            PoiSearch(this, PoiSearch.Query(keyword, "", "").apply { pageSize = 20 }).also {
                it.setOnPoiSearchListener(this)
                it.searchPOIAsyn()
            }
        } catch (error: Exception) {
            status.text = "搜索失败，请重试"
        }
    }

    override fun onPoiSearched(result: PoiResult?, code: Int) {
        if (code != 1000 || result == null) {
            status.text = "搜索失败，请重试"
            return
        }
        val found = result.pois.orEmpty().mapNotNull(::placeFromPoi)
        if (found.isEmpty()) {
            status.text = "没有找到相关地点"
            return
        }
        renderPlaces(found)
        selected = found.first()
        ignoreCameraChange = true
        map.animateCamera(CameraUpdateFactory.newLatLngZoom(
            LatLng(found.first().latitude, found.first().longitude), 16f))
    }

    override fun onPoiItemSearched(item: PoiItem?, code: Int) = Unit

    private fun placeFromPoi(item: PoiItem): Place? {
        val point = item.latLonPoint ?: return null
        return Place(item.title.orEmpty(), item.snippet.orEmpty(),
            point.latitude, point.longitude)
    }

    private fun renderPlaces(items: List<Place>) {
        places = items
        status.text = when {
            items.isEmpty() -> "没有找到地点"
            viewOnly -> items.first().name
            else -> "选择一个地点"
        }
        placesList.adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1,
            items.map { "${it.name}\n${it.address}" })
    }

    private fun choosePlace(position: Int) {
        val place = places.getOrNull(position) ?: return
        if (viewOnly) return
        selected = place
        status.text = "已选择：${place.name}"
        ignoreCameraChange = true
        map.animateCamera(CameraUpdateFactory.newLatLngZoom(
            LatLng(place.latitude, place.longitude), 16f))
    }

    private fun sendSelected() {
        val place = selected ?: run {
            Toast.makeText(this, "请先选择一个地点", Toast.LENGTH_SHORT).show()
            return
        }
        setResult(RESULT_OK, Intent().apply {
            putExtra("name", place.name)
            putExtra("address", place.address)
            putExtra("latitude", place.latitude)
            putExtra("longitude", place.longitude)
        })
        finish()
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

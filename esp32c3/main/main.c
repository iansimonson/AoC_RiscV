/*
 * SPDX-FileCopyrightText: 2010-2022 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: CC0-1.0
 */

#include <stdio.h>
#include <inttypes.h>
#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include "freertos/task.h"
#include "esp_chip_info.h"
#include "esp_flash.h"
#include "esp_system.h"
#include "esp_wifi.h"
#include "nvs_flash.h"
#include "esp_http_client.h"
#include "esp_crt_bundle.h"
#include "esp_log.h"

static EventGroupHandle_t g_wifi_event_group;

#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT BIT1
#define SSID CONFIG_ESP_WIFI_SSID
#define PASSWORD CONFIG_ESP_WIFI_PASSWORD
#define TOKEN CONFIG_ESP_WIFI_AOC_TOKEN
#define ESP_WIFI_SCAN_AUTH_MODE_THRESHOLD WIFI_AUTH_WPA2_PSK

static const char *TAG = "AOC Downloader";

static void event_handler(void *arg, esp_event_base_t event_base, int32_t event_id, void *event_data);
static void download_aoc_problem(int day);

void app_main(void)
{
    esp_err_t rc = nvs_flash_init();
    if (rc == ESP_ERR_NVS_NO_FREE_PAGES || rc == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        rc = nvs_flash_init();
    }

    g_wifi_event_group = xEventGroupCreate();

    ESP_ERROR_CHECK(rc);
    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    esp_netif_create_default_wifi_sta();

    wifi_init_config_t wifi_init_config = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&wifi_init_config));

    esp_event_handler_instance_t instance_any_id;
    esp_event_handler_instance_t instance_got_ip;
    ESP_ERROR_CHECK(esp_event_handler_instance_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL, &instance_any_id));
    ESP_ERROR_CHECK(esp_event_handler_instance_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &event_handler, NULL, &instance_got_ip));

    wifi_config_t wifi_config = {
        .sta = {
            .ssid = SSID,
            .password = PASSWORD,
            .threshold.authmode = ESP_WIFI_SCAN_AUTH_MODE_THRESHOLD,
        }
    };
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "Wifi Initialized");

    EventBits_t bits = xEventGroupWaitBits(g_wifi_event_group, WIFI_CONNECTED_BIT | WIFI_FAIL_BIT, pdFALSE, pdFALSE, portMAX_DELAY);

    if (bits & WIFI_CONNECTED_BIT) {
        ESP_LOGI(TAG, "EYY connected to wifi SSID:%s password%s", SSID, PASSWORD);
    } else if (bits & WIFI_FAIL_BIT) {
        ESP_LOGE(TAG, "Failed to connect to wifi SSID:%s password%s", SSID, PASSWORD);
    } else {
        ESP_LOGW(TAG, "Unexpected event!");
    }

    printf("Go ahead with downloading?\n");
    char response = 0xff;
    do {
        response = fgetc(stdin);
    } while (response == 0xff);
    if (response == 'Y' || response == 'y') {
        download_aoc_problem(1);
    } else {
        printf("Got %c so skipping download. Terminating...\n", response);
    }


    ESP_ERROR_CHECK(esp_wifi_stop());

    ESP_ERROR_CHECK(esp_wifi_deinit());
    ESP_ERROR_CHECK(nvs_flash_deinit());
    printf("DONE. Hit reset if you want to go again\n");
}

static int retry_num;
#define AOC_MAX_RETIRES 10

static void event_handler(void *arg, esp_event_base_t event_base, int32_t event_id, void *event_data)
{
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        ESP_LOGI(TAG, "connect to AP failed");
        if (retry_num < AOC_MAX_RETIRES) {
            esp_wifi_connect();
            retry_num += 1;
            ESP_LOGI(TAG, "retrying connect to AP");
        } else {
            xEventGroupSetBits(g_wifi_event_group, WIFI_FAIL_BIT);
        }
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t *event = (ip_event_got_ip_t *) event_data;
        ESP_LOGI(TAG, "got ip:" IPSTR, IP2STR(&event->ip_info.ip));
        retry_num = 0;
        xEventGroupSetBits(g_wifi_event_group, WIFI_CONNECTED_BIT);
    }
}

esp_err_t _http_event_handler(esp_http_client_event_t *evt)
{
    switch(evt->event_id) {
        case HTTP_EVENT_ERROR:
            ESP_LOGI(TAG, "HTTP_EVENT_ERROR");
            break;
        case HTTP_EVENT_ON_CONNECTED:
            ESP_LOGI(TAG, "HTTP_EVENT_ON_CONNECTED");
            break;
        case HTTP_EVENT_HEADER_SENT:
            ESP_LOGI(TAG, "HTTP_EVENT_HEADER_SENT");
            break;
        case HTTP_EVENT_ON_HEADER:
            ESP_LOGI(TAG, "HTTP_EVENT_ON_HEADER");
            printf("%.*s", evt->data_len, (char*)evt->data);
            break;
        case HTTP_EVENT_ON_DATA:
            ESP_LOGI(TAG, "HTTP_EVENT_ON_DATA, len=%d", evt->data_len);
            printf("%.*s", evt->data_len, (char*)evt->data);

            break;
        case HTTP_EVENT_ON_FINISH:
            ESP_LOGI(TAG, "HTTP_EVENT_ON_FINISH");
            break;
        case HTTP_EVENT_DISCONNECTED:
            ESP_LOGI(TAG, "HTTP_EVENT_DISCONNECTED");
            break;
        default:
            ESP_LOGI(TAG, "OTHER HTTP EVENT");
    }
    return ESP_OK;
}

#define Kilobyte 1024
#define HTTP_RESPONSE_MAX_SIZE 40*Kilobyte
#define AOC_SERVER "https://adventofcode.com"

static void download_aoc_problem(int day)
{

    ESP_LOGI(TAG, "Downloading day %d", day);
    char url_buf[48] = {0};
    sprintf(url_buf, "%s/2023/day/%d/input", AOC_SERVER, day);
    // sprintf(url_buf, "%s/", AOC_SERVER);
    char session_buf[196] = {0};
    sprintf(session_buf, "session=%s", TOKEN);
    esp_http_client_config_t config = {
        .url = url_buf,
        .event_handler = _http_event_handler,
        .user_agent = "ESP32 Adv. Of Code Downloader",
        .skip_cert_common_name_check = true,
        .transport_type = HTTP_TRANSPORT_OVER_SSL,
        .crt_bundle_attach = esp_crt_bundle_attach,
    };

    ESP_LOGI(TAG, "Initializing http client");

    esp_http_client_handle_t client = esp_http_client_init(&config);
    ESP_ERROR_CHECK(esp_http_client_set_header(client, "Cookie", session_buf));
    esp_err_t err = esp_http_client_perform(client);

    if (err == ESP_OK) {
        ESP_LOGI(TAG, "Status = %d, content_length = %lld", esp_http_client_get_status_code(client), esp_http_client_get_content_length(client));
    } else {
        ESP_LOGW(TAG, "Error performing request: %d", err);
    }

    esp_http_client_cleanup(client);
}

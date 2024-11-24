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

char *input = NULL;
u32_t input_len = 0;
u32_t data_len = 0;

extern void day1_part1(char *input, u32_t len);
extern void day1_part2(char *input, u32_t len);

typedef void (*solve_fn)(char*,u32_t);

static void unimplemented(char *input, u32_t len)
{
    (void) input;
    (void) len;
    printf("This day is unimplemented\n");
}

solve_fn solutions_p1[25] = {
    day1_part1,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
};

solve_fn solutions_p2[25] = {
    day1_part2,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
    unimplemented,
};

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

    input = NULL;
    input_len = 0;
    data_len = 0;

    printf("Enter Day to Solve:\n");
    char next = 0xff;
    char buffer[3] = {0};
    int count = 0;
    do {
        next = fgetc(stdin);
        vTaskDelay(1);
        if (next != 0xff && next != 0x0a) {
            buffer[count++] = next;
        }
    } while (count < 2 && next != 0x0A);
    if (count > 0) {
        int day = strtol(buffer, NULL, 10);
        if (day < 1 || day > 25) {
            printf("Day out of range [1,25] got %d. Exiting...\n", day);
        } else {
            solve_fn part1 = solutions_p1[day - 1];
            solve_fn part2 = solutions_p2[day - 1];
            printf("Downloading day %d\n", day);
            download_aoc_problem(day);
            printf("Downloaded input. input= %p, input_len= %lu, data_len= %lu\n", input, input_len, data_len);
            // DO SOLUTION
            printf("Running Part 1:\n");
            part1(input, data_len);
            printf("Running Part 2:\n");
            part2(input, data_len);
        }
    } else {
        printf("No day selected so skipping download. Terminating...\n");
    }

    free(input);
    input = NULL;
    input_len = 0;


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
            if (strcmp(evt->header_key, "Content-Length") == 0) {
                printf("Got Content-Length! - %s\n", evt->header_value);
                u32_t content_length = strtol(evt->header_value, NULL, 10);
                input = malloc(content_length);
                if (input == NULL) {
                    ESP_LOGE(TAG, "Failed to malloc input buffer of size %lu. Exiting!", content_length);
                    exit(1);
                }
                input_len = content_length;
            }
            break;
        case HTTP_EVENT_ON_DATA: {
            ESP_LOGI(TAG, "HTTP_EVENT_ON_DATA, len=%d", evt->data_len);
            int len = evt->data_len;
            if (len + data_len > input_len) {
                ESP_LOGE(TAG, "Received too much data got: %lu vs expected: %lu", len + data_len, input_len);
                exit(1);
            }
            memcpy(input + data_len, evt->data, len);
            data_len += len;
        } break;
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

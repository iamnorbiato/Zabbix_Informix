<?php
namespace Modules\InformixSqlTopN\Actions;

use API, CControllerDashboardWidgetView, CControllerResponseData;

class WidgetView extends CControllerDashboardWidgetView {
    protected function doAction(): void {
        $item = API::Item()->get([
            'output' => ['itemid', 'name', 'lastvalue', 'value_type'],
            'itemids' => (array) $this->fields_values['itemid'],
            'webitems' => true
        ]);

        $rows = [];
        $metric_keys = [
            0 => 'runtime', 1 => 'executions', 2 => 'avg_time', 3 => 'disk_reads',
            4 => 'buffer_reads', 5 => 'cache_ratio', 6 => 'lock_waits',
            7 => 'lock_wait_time', 8 => 'io_waits', 9 => 'disk_sorts',
            10 => 'memory_sorts', 11 => 'estimated_cost', 12 => 'estimated_rows',
            13 => 'actual_rows', 14 => 'read_write_ratio'
        ];
        $metric = $metric_keys[(int) ($this->fields_values['metric'] ?? 0)] ?? 'runtime';
        $value = $item[0]['lastvalue'] ?? '';

        if ($value === '' && $item) {
            $history = API::History()->get([
                'output' => API_OUTPUT_EXTEND,
                'itemids' => $item[0]['itemid'],
                'history' => $item[0]['value_type'],
                'sortfield' => 'clock',
                'sortorder' => ZBX_SORT_DOWN,
                'limit' => 1
            ]);
            $value = $history[0]['value'] ?? '';
        }

        if ($value !== '') {
            foreach (preg_split('/\R/', $value) as $line) {
                if (trim($line) === '') continue;
                $fields = explode('|', $line);
                if (count($fields) < 23) continue;
                // The deployed trace SQL exists in two compatible layouts.  Do
                // not use field count alone: an older trace row may contain a
                // literal pipe in the statement text and therefore look like
                // the newer 26-field layout.
                $none_index = array_search('<None>', array_map('trim', $fields), true);
                $is_new_layout = count($fields) >= 26
                    && $none_index !== 20 && $none_index !== 21 && $none_index !== 22;
                if ($is_new_layout) {
                    $row = [
                    'sql_id' => $fields[0], 'sid' => $fields[1], 'type' => $fields[2],
                    'runtime' => $fields[3], 'executions' => $fields[4], 'avg_time' => $fields[5],
                    'max_time' => $fields[6], 'disk_reads' => $fields[7], 'buffer_reads' => $fields[8],
                    'disk_writes' => $fields[9], 'buffer_writes' => $fields[10], 'read_write_ratio' => $fields[11],
                    'cache_ratio' => $fields[12], 'lock_waits' => $fields[13], 'lock_wait_time' => $fields[14],
                    'io_waits' => $fields[15], 'sorts' => $fields[17], 'disk_sorts' => $fields[18],
                    'memory_sorts' => $fields[19], 'estimated_cost' => $fields[20],
                    'estimated_rows' => $fields[21], 'actual_rows' => $fields[22], 'database' => $fields[23],
                    'preview' => $fields[24],
                    'full' => preg_replace('/^\s*\d+\|<None>\|/', '', rtrim(implode('|', array_slice($fields, 25)), '|'))
                    ];
                }
                else {
                    $row = [
                        'sql_id' => $fields[0], 'sid' => $fields[1], 'type' => $fields[2],
                        'runtime' => $fields[3], 'executions' => $fields[4], 'avg_time' => $fields[5],
                        'max_time' => $fields[6], 'disk_reads' => $fields[7], 'buffer_reads' => $fields[8],
                        'disk_writes' => 0, 'buffer_writes' => 0, 'read_write_ratio' => '',
                        'cache_ratio' => $fields[9], 'lock_waits' => $fields[10], 'lock_wait_time' => $fields[11],
                        'io_waits' => $fields[12], 'sorts' => $fields[14], 'disk_sorts' => $fields[15],
                        'memory_sorts' => $fields[16], 'estimated_cost' => $fields[17],
                        'estimated_rows' => $fields[18], 'actual_rows' => $fields[19], 'database' => $fields[20],
                        'preview' => $fields[21],
                        'full' => preg_replace('/^\s*\d+\|<None>\|/', '', rtrim(implode('|', array_slice($fields, 22)), '|'))
                    ];
                }
                $rows[] = $row;
            }
        }

        usort($rows, static function (array $left, array $right) use ($metric): int {
            return (float) ($right[$metric] ?? 0) <=> (float) ($left[$metric] ?? 0);
        });

        $this->setResponse(new CControllerResponseData([
            'name' => $this->getInput('name', $this->widget->getName()),
            'rows' => $rows,
            'metric' => $metric,
            'fields_values' => $this->fields_values,
            'user' => ['debug_mode' => $this->getDebugMode()]
        ]));
    }
}

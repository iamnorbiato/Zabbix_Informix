class WidgetInformixSqlTopN extends CWidget {
    onInitialize() {
        super.onInitialize();
        this._rows = [];
    }

    processUpdateResponse(response) {
        this._rows = response.rows || [];
        super.processUpdateResponse(response);
    }

    setContents(response) {
        super.setContents(response);
        response = response || {};
        const fields_values = response.fields_values || {};
        const rows = Array.isArray(response.rows) ? response.rows : this._rows;
        const metric_labels = {
            runtime: 'maximum runtime', executions: 'total executions', avg_time: 'average time',
            disk_reads: 'disk reads', buffer_reads: 'buffer reads', cache_ratio: 'cache ratio',
            lock_waits: 'lock waits', lock_wait_time: 'lock wait time', io_waits: 'I/O waits',
            disk_sorts: 'disk sorts', memory_sorts: 'memory sorts', estimated_cost: 'estimated cost',
            estimated_rows: 'estimated rows', actual_rows: 'actual rows', read_write_ratio: 'read/write ratio'
        };
        const metric = response.metric || fields_values.metric || 'runtime';
        this._body.style.setProperty('--preview-width', `${fields_values.preview_width || 320}px`);
        const table = this._body.querySelector('.informix-sql-top-n-table');
        const detail = this._body.querySelector('.informix-sql-top-n-detail');

        if (!table || !detail) {
            return;
        }

        const metric_options = [
            ['runtime', 'Maximum runtime'], ['executions', 'Total executions'],
            ['avg_time', 'Average time'], ['disk_reads', 'Disk reads'],
            ['buffer_reads', 'Buffer reads'], ['cache_ratio', 'Cache ratio'],
            ['lock_waits', 'Lock waits'], ['lock_wait_time', 'Lock wait time'],
            ['io_waits', 'I/O waits'], ['disk_sorts', 'Disk sorts'],
            ['memory_sorts', 'Memory sorts'], ['estimated_cost', 'Estimated cost'],
            ['estimated_rows', 'Estimated rows'], ['actual_rows', 'Actual rows'],
            ['read_write_ratio', 'Read/write ratio']
        ];
        table.innerHTML = `<div class="informix-sql-heading"><h3>Top SQL by ${this._escape(metric_labels[metric] || metric)}</h3><label>Metric <select class="informix-sql-metric">${metric_options.map(([key, label]) => `<option value="${key}"${key === metric ? ' selected' : ''}>${label}</option>`).join('')}</select></label></div>`;
        const metric_select = table.querySelector('.informix-sql-metric');
        metric_select.addEventListener('change', () => {
            const selected = metric_select.value;
            rows.sort((a, b) => Number(b[selected] || 0) - Number(a[selected] || 0));
            const heading = table.querySelector('.informix-sql-heading h3');
            if (heading) {
                heading.textContent = `Top SQL by ${metric_labels[selected] || selected}`;
            }
            this._renderRows(table, detail, rows, selected, metric_labels);
        });
        detail.innerHTML = '<h3>SQL detail</h3><div class="informix-sql-empty">Select a SQL row to view the full statement.</div>';

        const header = ['Rank', 'SQL ID', 'Type', 'Avg time (ms)', 'Executions', 'Cost', 'Reads', 'Writes', 'R/W ratio', 'Status', 'SQL preview'];
        const table_el = document.createElement('table');
        table_el.className = 'informix-sql-table';
        table_el.innerHTML = '<thead><tr>' + header.map((v) => `<th>${v}</th>`).join('') + '</tr></thead>';
        const body = document.createElement('tbody');

        rows.forEach((row, index) => {
            const tr = document.createElement('tr');
            tr.dataset.rowIndex = String(index);
            const runtime_ms = Number(row.avg_time || 0) * 1000;
            const status = runtime_ms > 1000 ? 'SLOW' : 'OK';
            tr.className = status === 'SLOW' ? 'informix-sql-slow' : '';
            tr.innerHTML = [index + 1, row.sql_id, row.type, runtime_ms.toFixed(1),
                row.executions, row.estimated_cost, row.disk_reads, row.disk_writes,
                row.read_write_ratio]
                .map((v) => `<td>${this._escape(v)}</td>`).join('')
                + `<td><span class="informix-sql-status ${status.toLowerCase()}">${status}</span></td>`
                + `<td>${this._escape(this._cleanSql(row.preview))}</td>`;
            body.appendChild(tr);
        });

        body.addEventListener('click', (event) => {
            const row_element = event.target.closest('tr[data-row-index]');
            if (!row_element || !body.contains(row_element)) {
                return;
            }

            const row = rows[Number(row_element.dataset.rowIndex)];
            if (!row) {
                return;
            }

            body.querySelectorAll('tr.informix-sql-selected').forEach((selected) => {
                selected.classList.remove('informix-sql-selected');
            });
            row_element.classList.add('informix-sql-selected');
            detail.innerHTML = `<h3>SQL detail — selected SQL ID ${this._escape(row.sql_id)}</h3><pre>${this._escape(this._cleanSql(row.full))}</pre>`;
        });

        table_el.appendChild(body);
        table.appendChild(table_el);
    }

    _renderRows(table, detail, rows, metric, metric_labels) {
        const old_table = table.querySelector('.informix-sql-table');
        if (old_table) old_table.remove();
        const header = ['Rank', 'SQL ID', 'Type', 'Avg time (ms)', 'Executions', 'Cost', 'Reads', 'Writes', 'R/W ratio', 'Status', 'SQL preview'];
        const table_el = document.createElement('table');
        table_el.className = 'informix-sql-table';
        table_el.innerHTML = '<thead><tr>' + header.map((v) => `<th>${v}</th>`).join('') + '</tr></thead>';
        const body = document.createElement('tbody');
        rows.forEach((row, index) => {
            const tr = document.createElement('tr');
            tr.dataset.rowIndex = String(index);
            const runtime_ms = Number(row.avg_time || 0) * 1000;
            const status = runtime_ms > 1000 ? 'SLOW' : 'OK';
            tr.innerHTML = [index + 1, row.sql_id, row.type, runtime_ms.toFixed(1), row.executions, row.estimated_cost, row.disk_reads, row.disk_writes, row.read_write_ratio]
                .map((v) => `<td>${this._escape(v)}</td>`).join('')
                + `<td><span class="informix-sql-status ${status.toLowerCase()}">${status}</span></td><td>${this._escape(this._cleanSql(row.preview))}</td>`;
            tr.addEventListener('click', () => {
                body.querySelectorAll('tr.informix-sql-selected').forEach((selected) => selected.classList.remove('informix-sql-selected'));
                tr.classList.add('informix-sql-selected');
                detail.innerHTML = `<h3>SQL detail — selected SQL ID ${this._escape(row.sql_id)}</h3><pre>${this._escape(this._cleanSql(row.full))}</pre>`;
            });
            body.appendChild(tr);
        });
        table_el.appendChild(body);
        table.appendChild(table_el);
    }

    _escape(value) {
        const div = document.createElement('div');
        div.textContent = value == null ? '' : String(value);
        return div.innerHTML;
    }

    _cleanSql(value) {
        return String(value == null ? '' : value).replace(/\\\s*/g, '\n').trim();
    }
}

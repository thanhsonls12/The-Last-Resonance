"""Generate a static asset inventory; never modifies source assets.

Run: python tools/audit_assets.py
References indicate declarations, not proof of execution or safe deletion.
"""

import hashlib
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IGNORED = {'.import', '.uid', '.md'}
TEXT = {'.gd', '.tscn', '.tres', '.godot', '.cfg', '.gdshader', '.py', '.ps1'}


def main():
    assets = sorted(p for p in (ROOT / 'assets').rglob('*')
                    if p.is_file() and p.suffix not in IGNORED and not p.name.startswith('.'))
    paths = {p.relative_to(ROOT).as_posix(): p for p in assets}
    references = defaultdict(list)
    missing = defaultdict(list)
    sources = [ROOT / 'project.godot', ROOT / 'export_presets.cfg']
    for folder in ('src', 'scenes', 'resources', 'assets', 'tools', 'tests'):
        sources.extend(p for p in (ROOT / folder).rglob('*')
                       if p.is_file() and p.suffix in TEXT and p != Path(__file__).resolve())
    for source in sorted(set(sources)):
        if not source.exists():
            continue
        relative = source.relative_to(ROOT).as_posix()
        scope = ('tooling' if relative.startswith(('tools/', 'src/tools/', 'scenes/editor/'))
                 else 'test' if relative.startswith('tests/') else 'project')
        content = source.read_text(encoding='utf-8-sig')
        constants = dict(re.findall(r'const\s+(\w+)\s*(?::=|=)\s*"(res://assets/[^"\n]*)"', content))
        for line_no, line in enumerate(content.splitlines(), 1):
            if line.lstrip().startswith('#'):
                continue
            values = [(m, 'literal') for m in re.findall(r'["\']((?:res://)?assets/[^"\'\n]+)["\']', line)]
            for name, prefix in constants.items():
                values.extend((prefix + tail, 'constant_concat') for tail in
                              re.findall(r'\b' + re.escape(name) + r'\s*\+\s*"([^"\n]+)"', line))
            for value, method in values:
                path = value.removeprefix('res://')
                if path.endswith('/'):
                    continue
                evidence = {'file': relative, 'line': line_no, 'scope': scope, 'method': method}
                if '%s' in path or re.search(r'\{[^{}]+\}', path):
                    tokens = re.split(r'(%s|\{[^{}]+\})', path)
                    pattern = ''.join('[^/]+' if token == '%s' or token.startswith('{')
                                      else re.escape(token) for token in tokens)
                    for candidate in paths:
                        if re.fullmatch(pattern, candidate):
                            references[candidate].append(dict(evidence, method='dynamic_candidate'))
                elif path in paths:
                    references[path].append(evidence)
                elif not (ROOT / path).exists():
                    missing[path].append(evidence)
    rows = []
    hashes = defaultdict(list)
    names = defaultdict(list)
    for path, file in paths.items():
        digest = hashlib.sha256(file.read_bytes()).hexdigest()
        hashes[digest].append(path)
        names[file.stem].append(path)
        refs = references[path]
        project_refs = [r for r in refs if r['scope'] == 'project']
        status = ('project_reference' if any(r['method'] != 'dynamic_candidate' for r in project_refs)
                  else 'dynamic_candidate' if project_refs
                  else 'tooling_or_test_only' if refs else 'no_reference_found')
        parts = path.split('/')
        group = '/'.join(parts[1:3]) if parts[1] in ('audio', 'models') else parts[1]
        rows.append({'path': path, 'group': group, 'bytes': file.stat().st_size,
                     'sha256': digest, 'status': status, 'references': refs,
                     'license_status': 'unverified'})
    result = {
        'method': 'Static declarations; includes constant concatenation, %s and brace-template candidates. No runtime reachability, GLB embedded dependency, visual or audio validation.',
        'total_files': len(rows), 'total_bytes': sum(r['bytes'] for r in rows),
        'status_counts': dict(Counter(r['status'] for r in rows)),
        'missing_literal_references': dict(sorted(missing.items())),
        'identical_content_groups': [v for v in hashes.values() if len(v) > 1],
        'same_stem_groups': [v for v in names.values() if len(v) > 1],
        'assets': rows,
    }
    output = ROOT / 'docs' / 'ASSET_INVENTORY.json'
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    lines = ['# Danh mục asset (tự động)', '',
             'Tạo lại bằng `python tools/audit_assets.py`. Chi tiết tham chiếu và SHA-256: [ASSET_INVENTORY.json](ASSET_INVENTORY.json).', '',
             'Đây là kiểm kê tĩnh: có tham chiếu không chứng minh đã chạy; không tìm thấy tham chiếu không có nghĩa được phép xóa. Không phân tích dependency nhúng trong GLB. Bỏ qua `.import`, `.uid`, Markdown và file ẩn.', '',
             '- `project_reference`: có khai báo trong mã/resource/cấu hình dự án.',
             '- `dynamic_candidate`: khớp mẫu đường dẫn động; cần xác nhận trong game.',
             '- `tooling_or_test_only`: chỉ thấy trong công cụ hoặc test.',
             '- `no_reference_found`: chưa tìm thấy tham chiếu theo phương pháp trên.', '',
             f'Tổng: {len(rows)} file, {result["total_bytes"] / 1048576:.2f} MiB trên đĩa (không phải RAM/VRAM hay dung lượng bản export).', '',
             '| Nhóm | File | MiB |', '| --- | ---: | ---: |']
    for group in sorted({r['group'] for r in rows}):
        subset = [r for r in rows if r['group'] == group]
        lines.append(f'| {group} | {len(subset)} | {sum(r["bytes"] for r in subset) / 1048576:.2f} |')
    lines += ['', '## Tham chiếu literal không có file', '']
    lines += [f'- `{p}` — ' + ', '.join(f'{r["file"]}:{r["line"]}' for r in refs)
              for p, refs in sorted(missing.items())] or ['Không phát hiện.']
    lines += ['', '## Các nhóm trùng nội dung SHA-256', '']
    lines += ['- ' + ', '.join(f'`{p}`' for p in group) for group in result['identical_content_groups']] or ['Không phát hiện.']
    lines += ['', '## Danh sách đầy đủ', '',
              'Giấy phép của mọi mục hiện là `unverified`; xem báo cáo kiểm kê để biết bằng chứng nguồn.', '',
              '| Asset | KiB | Phân loại |', '| --- | ---: | --- |']
    lines += [f'| `{r["path"]}` | {r["bytes"] / 1024:.1f} | {r["status"]} |' for r in rows]
    (ROOT / 'docs' / 'ASSET_INVENTORY.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in result.items() if k not in ('assets', 'same_stem_groups')}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()

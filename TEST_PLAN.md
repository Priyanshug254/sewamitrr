# SewaMitr Manual Test Plan

This document outlines the manual testing procedures to verify the functionality of the SewaMitr Admin Frontend and Backend.

## 1. Authentication & Authorization

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| A1 | State Admin Login | 1. Go to `/login`<br>2. Enter `state.admin@sewamitr.in` / `SewaMitr@2024`<br>3. Click Login | Redirects to `/state` dashboard. | |
| A2 | City Admin Login | 1. Go to `/login`<br>2. Enter `ranchi.admin@sewamitr.in` / `SewaMitr@2024`<br>3. Click Login | Redirects to `/city/[ranchi-id]` dashboard. | |
| A3 | CRC Supervisor Login | 1. Go to `/login`<br>2. Enter `crc.ranchi.1@sewamitr.in` / `SewaMitr@2024`<br>3. Click Login | Redirects to `/crc/[zone-id]` dashboard. | |
| A4 | Ward Supervisor Login | 1. Go to `/login`<br>2. Enter `ward.ranchi.1@sewamitr.in` / `SewaMitr@2024`<br>3. Click Login | Redirects to `/ward/[ward-id]` dashboard. | |
| A5 | Invalid Login | 1. Go to `/login`<br>2. Enter invalid credentials<br>3. Click Login | Shows error message "Invalid login credentials". | |
| A6 | Unauthorized Access | 1. Login as City Admin (Ranchi)<br>2. Try to access `/city/[dhanbad-id]` | Redirects back to `/city/[ranchi-id]` or shows 404/403. | |
| A7 | Sign Out | 1. Click "Sign out" button in header | Redirects to `/login`. | |

## 2. State Admin Dashboard (`/state`)

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| S1 | KPI Display | 1. Login as State Admin<br>2. Check top cards | Shows Total, Open, Resolved, SLA Compliance stats. | |
| S2 | City List | 1. Check "City Overview" table | Lists Ranchi, Dhanbad, Jamshedpur with correct issue counts. | |
| S3 | Navigation | 1. Click "Ranchi" in table | Navigates to `/city/[ranchi-id]`. | |
| S4 | Recent Issues | 1. Check "Recent Activity" feed | Shows latest issues from all cities. | |

## 3. City Admin Dashboard (`/city/[id]`)

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| C1 | Ward List | 1. Check "Wards" section | Lists all wards (e.g., 55 for Ranchi). | |
| C2 | Zone List | 1. Check "CRC Zones" section | Lists all zones with supervisors. | |
| C3 | Zone Drill-down | 1. Click a Zone | Navigates to `/crc/[zone-id]`. | |

## 4. CRC Supervisor Dashboard (`/crc/[id]`)

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| Z1 | Unverified Queue | 1. Check "Unverified Issues" | Lists issues with status `submitted`. | |
| Z2 | Verify Action | 1. Click "Verify" on an issue | (Mock) UI updates, issue moves to verified/forwarded list. | |
| Z3 | Reject Action | 1. Click "Reject" on an issue | (Mock) UI updates, issue removed from queue. | |

## 5. Ward Supervisor Dashboard (`/ward/[id]`)

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| W1 | Forwarded Queue | 1. Check "Forwarded Issues" | Lists issues with status `forwarded_to_ward`. | |
| W2 | Assign Contractor | 1. Click "Assign Contractor" | Opens modal/dropdown to select contractor. | |
| W3 | Contractor List | 1. Check "Available Contractors" | Lists workers assigned to this city. | |

## 6. Report Details (`/reports/[id]`)

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| R1 | Data Display | 1. Open any issue | Shows category, description, address, photos. | |
| R2 | Map Location | 1. Check location details | Shows lat/lng and address. | |
| R3 | SLA Status | 1. Check SLA section | Shows due date and status (Compliant/Breached). | |
| R4 | Timeline | 1. Check Activity Timeline | Shows history of status changes. | |

## 7. Workers Management (`/workers`)

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| K1 | List View | 1. Go to `/workers` | Lists all contractors with ratings. | |
| K2 | Filtering | 1. Login as City Admin | Shows only contractors for that city. | |

## 8. Enhanced Features

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| E1 | Realtime Updates | 1. Open Dashboard<br>2. In Supabase, insert new issue | Dashboard updates count/list without refresh. | |
| E2 | Map Rendering | 1. Check Map component | Shows markers and ward polygons. | |
| E3 | Charts | 1. Check Analytics section | Charts render with data. | |

## 9. Database & RLS

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| D1 | Data Isolation | 1. Run SQL: `SELECT * FROM issues` as 'ranchi_admin' | Returns only Ranchi issues. | |
| D2 | Audit Logging | 1. Update an issue status | New row created in `audit_logs`. | |

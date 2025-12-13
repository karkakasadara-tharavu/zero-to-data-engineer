# Lab 74: Dashboards and Deployment

## Objective
Learn to publish Power BI reports to the Power BI Service, create dashboards, configure scheduled refresh, implement row-level security, and manage workspaces for enterprise deployment.

## Prerequisites
- Completion of Labs 68-73
- Power BI Pro license (or trial)
- Power BI Desktop with completed reports
- Microsoft 365 organizational account

## Duration
90 minutes

---

## Part 1: Publishing to Power BI Service

### Power BI Service Overview

**Power BI Service (app.powerbi.com):**
- Cloud-based platform for sharing reports
- Dashboard creation
- Scheduled data refresh
- Collaboration features
- Mobile access

### Report vs Dashboard vs App

| Component | Description | Created In |
|-----------|-------------|------------|
| Report | Interactive pages with visuals | Desktop or Service |
| Dashboard | Single-page canvas with pinned tiles | Service only |
| App | Packaged collection of reports/dashboards | Service |
| Dataflow | Cloud-based ETL | Service |
| Dataset | Published data model | Desktop → Service |

### Exercise 1.1: Publish a Report

**Steps to publish:**

1. Open your report in Power BI Desktop
2. Click **Home** → **Publish**
3. Sign in with organizational account
4. Select destination workspace
5. Click **Select**

6. Wait for publishing to complete
7. Click the link to open in browser

### Workspace Structure

```
My Workspace (Personal)
├── Reports
├── Dashboards
├── Datasets
└── Dataflows

Sales Team Workspace (Shared)
├── Sales Report
├── Sales Dashboard
├── Sales Dataset
└── Members
    ├── Admin: John
    ├── Member: Jane
    └── Viewer: Bob
```

---

## Part 2: Creating Dashboards

### What is a Dashboard?

- Single page of tiles (pinned visuals)
- Mix tiles from multiple reports
- Always shows live data
- Entry point for exploration
- Mobile-optimized

### Dashboard vs Report

| Feature | Dashboard | Report |
|---------|-----------|--------|
| Pages | Single page | Multiple pages |
| Interactivity | Tile click → report | Full filtering |
| Data source | Tiles from reports | Direct from dataset |
| Creation | Pin from reports | Power BI Desktop |
| Q&A | Yes | Limited |

### Exercise 2.1: Create a Dashboard

**Step 1: Pin visuals from a report**

1. Open your report in Power BI Service
2. Hover over a visual
3. Click the pin icon 📌
4. Choose:
   - New dashboard (name it)
   - Existing dashboard
5. Click **Pin**

**Step 2: Pin more tiles**

Pin these key elements:
- KPI cards (Total Sales, Customers, Orders)
- Main trend chart
- Category breakdown
- Map (if applicable)

### Exercise 2.2: Add Custom Tiles

**Add a text tile:**
1. On dashboard, click **Edit** → **Add tile**
2. Select **Text box**
3. Add title or instructions
4. Click **Apply**

**Add an image:**
1. Add tile → Image
2. Enter image URL
3. Add link (optional)

**Add a video:**
1. Add tile → Video
2. Enter YouTube/Vimeo URL

### Exercise 2.3: Configure Tile Details

1. Hover over a tile
2. Click **More options** (...)
3. Select **Edit details**
4. Configure:
   - Title
   - Subtitle
   - Custom link
   - Time last refreshed

---

## Part 3: Natural Language Q&A

### Q&A Feature

Ask questions in natural language:
- "What were total sales last month?"
- "Top 10 customers by revenue"
- "Sales by category as a pie chart"

### Exercise 3.1: Use Q&A

1. On dashboard, click **Ask a question about your data**
2. Try these queries:
   - "Total sales"
   - "Sales by category"
   - "Top 5 products"
   - "Sales trend by month"

3. Pin useful results to dashboard

### Improve Q&A

1. In dataset settings, add **Featured Q&A questions**
2. Define **Synonyms** for better understanding
3. Add **Row labels** to tables

---

## Part 4: Scheduled Refresh

### Data Refresh Options

| Refresh Type | Description | Frequency |
|--------------|-------------|-----------|
| Manual | On-demand refresh | As needed |
| Scheduled | Automated at intervals | Up to 8x/day (Pro) |
| Incremental | Only new/changed data | Configurable |
| DirectQuery | Real-time from source | Continuous |

### Exercise 4.1: Configure Scheduled Refresh

**For SQL Server on-premises:**

1. Install On-premises Data Gateway
2. Configure gateway in Power BI Service

**Steps:**
1. Go to Workspace → Settings (gear icon)
2. Select **Datasets** tab
3. Click your dataset
4. Expand **Scheduled refresh**

5. Configure:
   - Refresh frequency: Daily
   - Time slots: Add multiple times
   - Time zone: Your local zone
   - Failure notifications: On

6. Click **Apply**

### Exercise 4.2: Set Up Gateway

**Download and install:**
1. Power BI Service → Settings → Manage gateways
2. Download On-premises data gateway
3. Install and configure

**Configure data source:**
1. In gateway, add data source
2. Enter SQL Server credentials
3. Test connection

**Use in dataset:**
1. Dataset settings → Gateway connection
2. Select your gateway
3. Map to data source

---

## Part 5: Row-Level Security (RLS)

### What is RLS?

Restrict data access at row level based on user identity.

**Example:** Sales reps see only their region's data.

### RLS Implementation Steps

1. Define roles in Power BI Desktop
2. Create filter expressions
3. Publish to service
4. Assign users to roles

### Exercise 5.1: Create RLS Roles

**In Power BI Desktop:**

1. Go to **Modeling** → **Manage roles**
2. Click **Create**
3. Name the role (e.g., "North Region")
4. Select table (e.g., DimCustomer)
5. Add filter expression:

```dax
[Region] = "North"
```

6. Click **Save**

**Create multiple roles:**
- "North Region": `[Region] = "North"`
- "South Region": `[Region] = "South"`
- "All Regions": (no filter)

### Exercise 5.2: Test RLS

1. Modeling → View as → Select role
2. Verify data is filtered correctly
3. Test each role

### Exercise 5.3: Dynamic RLS

Use user email for dynamic filtering:

```dax
[SalesRepEmail] = USERPRINCIPALNAME()
```

**How it works:**
1. Table has column with user emails
2. Filter matches logged-in user's email
3. Each user sees only their data

### Assign Users to Roles

**In Power BI Service:**

1. Go to dataset settings
2. Click **Security**
3. Select a role
4. Add members (email addresses)
5. Click **Add**

---

## Part 6: Workspace Management

### Workspace Types

| Type | Description | Use Case |
|------|-------------|----------|
| My Workspace | Personal | Development/testing |
| Workspace | Shared | Team collaboration |
| App | Packaged content | Distribution |

### Exercise 6.1: Create a Workspace

1. In Power BI Service, click **Workspaces**
2. Click **Create a workspace**
3. Configure:
   - Name: "Sales Team Analytics"
   - Description: Add description
   - Advanced: Premium capacity (if available)
4. Click **Save**

### Workspace Roles

| Role | Permissions |
|------|-------------|
| Admin | Full control, manage members |
| Member | Create, edit, publish content |
| Contributor | Create and edit content |
| Viewer | View content only |

### Exercise 6.2: Add Members

1. Open workspace
2. Click **Access**
3. Enter email address
4. Select role
5. Click **Add**

---

## Part 7: Creating Apps

### What is a Power BI App?

- Bundled collection of dashboards and reports
- Easy distribution
- Consistent experience
- Automatic updates

### Exercise 7.1: Create and Publish an App

**Step 1: Prepare workspace content**
- Finalize all reports
- Create dashboard
- Organize content

**Step 2: Create app**
1. In workspace, click **Create app**
2. Configure **Setup**:
   - App name
   - Description
   - Logo
   - Theme color

3. Configure **Navigation**:
   - Arrange content order
   - Group related items
   - Set landing page

4. Configure **Permissions**:
   - Entire organization, OR
   - Specific people/groups

5. Click **Publish app**

### Exercise 7.2: Update an App

When content changes:
1. Make changes to workspace content
2. Click **Update app**
3. Review changes
4. Click **Update app** to push changes

---

## Part 8: Sharing and Distribution

### Sharing Methods

| Method | Best For | License Required |
|--------|----------|-----------------|
| Share dashboard/report | Small teams | Pro for viewers |
| App | Large audiences | Pro for viewers |
| Publish to web | Public data | None |
| Embed in website | Custom apps | Embed license |
| Export PDF/PowerPoint | Offline distribution | Pro for creator |

### Exercise 8.1: Share a Report

**Direct sharing:**
1. Open report in Service
2. Click **Share**
3. Enter recipient email
4. Choose permissions:
   - Allow resharing
   - Allow building on dataset
5. Add message
6. Click **Send**

### Exercise 8.2: Publish to Web

⚠️ **Warning:** Data becomes publicly accessible!

1. Open report
2. File → Embed report → Publish to web
3. Confirm (understand risks)
4. Copy embed code or link
5. Use in website or blog

### Exercise 8.3: Export Options

**Export to PDF:**
1. Open report
2. Export → PDF
3. Configure options
4. Download

**Export to PowerPoint:**
1. Export → PowerPoint
2. Choose pages
3. Download .pptx

---

## Part 9: Monitoring and Usage

### Usage Metrics

Monitor who uses your content:

1. Open report/dashboard
2. Click **View usage metrics**
3. Review:
   - Views per day
   - Unique viewers
   - Viewing method (web, mobile)
   - Top viewers

### Exercise 9.1: Create Usage Report

1. Open usage metrics
2. Click **Create new usage report**
3. Customize for your needs
4. Save to workspace

### Audit Logs

For IT admins - track all Power BI activities:
- Who accessed what
- Export activities
- Sharing events
- Admin changes

---

## Part 10: Lab Summary and Quiz

### Key Concepts Learned

1. ✅ Publishing reports to Power BI Service
2. ✅ Creating dashboards from pinned tiles
3. ✅ Q&A natural language queries
4. ✅ Scheduled data refresh
5. ✅ Row-Level Security (RLS)
6. ✅ Workspace management
7. ✅ Creating and distributing apps
8. ✅ Sharing and distribution methods

### Deployment Checklist

Before going live:
- [ ] All visuals working correctly
- [ ] Data refresh configured
- [ ] RLS tested and verified
- [ ] Users assigned to roles
- [ ] Workspace permissions set
- [ ] App published (if applicable)
- [ ] Documentation complete

### Quiz

**Question 1:** Where can you create a dashboard in Power BI?
- a) Power BI Desktop only
- b) Power BI Service only
- c) Both Desktop and Service
- d) Excel

**Question 2:** What is the maximum refresh frequency for Pro licenses?
- a) 4 times per day
- b) 8 times per day
- c) 24 times per day
- d) Unlimited

**Question 3:** How do you restrict data access at the row level?
- a) Workspace roles
- b) Row-Level Security (RLS)
- c) Page filters
- d) Share permissions

**Question 4:** Which function returns the current user's email for dynamic RLS?
- a) USERNAME()
- b) USERPRINCIPALNAME()
- c) CURRENTUSER()
- d) EMAIL()

**Question 5:** What is a Power BI App?
- a) Mobile application
- b) Bundled collection of dashboards and reports
- c) Data transformation tool
- d) Development environment

### Answers
1. b) Power BI Service only
2. b) 8 times per day
3. b) Row-Level Security (RLS)
4. b) USERPRINCIPALNAME()
5. b) Bundled collection of dashboards and reports

---

## Next Lab
**Lab 75: Power BI and Data Engineering Integration** - Connect Power BI to your data warehouse with advanced features like incremental refresh and aggregations.

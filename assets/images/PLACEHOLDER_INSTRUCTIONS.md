# 🎨 Image Placeholders Guide

This folder is for visual assets that enhance the curriculum presentation on GitHub.

## Required Images for Branding

### 1. Company Banner
- **Filename**: `banner.png`
- **Recommended Size**: 1200 x 300 pixels
- **Format**: PNG with transparency or JPG
- **Usage**: Top of main README.md
- **Design Tips**:
  - Include company logo and tagline
  - Use brand colors
  - Keep it professional and clean
  - Example text: "Professional Data Engineering Training by [Your Company]"

### 2. Company Logo
- **Filename**: `logo.png`
- **Recommended Size**: 200 x 200 pixels
- **Format**: PNG with transparency
- **Usage**: Footer of main README.md and module headers
- **Design Tips**:
  - Square or circular format works best
  - High contrast for visibility
  - Matches company brand guidelines

### 3. Certification Badge (Optional)
- **Filename**: `certification_badge.png`
- **Recommended Size**: 400 x 400 pixels
- **Format**: PNG with transparency
- **Usage**: Displayed when students complete the course
- **Design Tips**:
  - Include course name
  - Completion year placeholder
  - Professional appearance suitable for LinkedIn

## Architecture Diagrams

These will be generated for each module (you can create them using tools like draw.io, Lucidchart, or PowerPoint):

### Module-Specific Diagrams
- `module_02_sql_query_flow.png` - Visual of query execution order
- `module_04_normalization_example.png` - Database normalization diagram
- `module_06_ssis_architecture.png` - SSIS package workflow
- `module_07_cdc_flow.png` - Change Data Capture process
- `module_08_powerbi_architecture.png` - BI solution architecture
- `module_09_capstone_erdiagram.png` - Complete data warehouse ERD

## How to Add Images

1. **Create/Design Your Images**
   - Use tools like Canva, Adobe Illustrator, PowerPoint, or Figma
   - Maintain consistent branding across all images

2. **Add to Repository**
   ```powershell
   # From repository root
   cp path/to/your/banner.png assets/images/banner.png
   cp path/to/your/logo.png assets/images/logo.png
   ```

3. **Update README References**
   The placeholders in README.md will automatically work once files are added:
   ```markdown
   ![Company Banner](./assets/images/banner.png)
   ![Company Logo](./assets/images/logo.png)
   ```

## Free Design Resources

If you need help creating images:

- **Canva** (Free tier): https://www.canva.com/
- **Logo Maker**: https://www.freelogodesign.org/
- **Icon Libraries**: https://fontawesome.com/, https://icons8.com/
- **Color Palettes**: https://coolors.co/

## Screenshot Guidelines

For module-specific screenshots (installation steps, SSMS, etc.):

- Use 16:9 aspect ratio when possible
- Annotate important areas with arrows/highlights
- Keep resolution at least 1280x720
- Save as PNG for clarity
- Organize in module-specific folders: `Module_XX/screenshots/`

---

**Note**: All image placeholders in markdown files are marked with comments:
```markdown
<!-- 🎨 PLACEHOLDER: Add your company banner here -->
```

Search for "🎨 PLACEHOLDER" across all files to find where images should be added.

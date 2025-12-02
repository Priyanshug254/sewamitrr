describe('Authentication Flow', () => {
    it('should successfully login as state admin', () => {
        cy.visit('/login')
        cy.get('input[name="email"]').type('state.admin@sewamitr.in')
        cy.get('input[name="password"]').type('SewaMitr@2024')
        cy.get('button[type="submit"]').click()

        cy.url().should('include', '/state')
        cy.contains('State Admin Dashboard')
    })

    it('should fail with invalid credentials', () => {
        cy.visit('/login')
        cy.get('input[name="email"]').type('wrong@email.com')
        cy.get('input[name="password"]').type('wrongpass')
        cy.get('button[type="submit"]').click()

        cy.contains('Invalid login credentials')
    })
})

describe('State Dashboard', () => {
    beforeEach(() => {
        // Mock login or use custom command
        cy.login('state.admin@sewamitr.in', 'SewaMitr@2024')
        cy.visit('/state')
    })

    it('should display KPI cards', () => {
        cy.contains('Total Issues')
        cy.contains('SLA Compliance')
    })

    it('should navigate to city dashboard', () => {
        cy.contains('Ranchi').click()
        cy.url().should('include', '/city/')
        cy.contains('City Admin Dashboard')
    })
})

describe('Issue Management', () => {
    beforeEach(() => {
        cy.login('crc.ranchi.1@sewamitr.in', 'SewaMitr@2024')
        cy.visit('/crc/zone-id-here') // Replace with actual ID
    })

    it('should display unverified issues', () => {
        cy.contains('Unverified Issues Queue')
    })

    it('should allow verifying an issue', () => {
        cy.get('.issue-card').first().within(() => {
            cy.contains('Verify').click()
        })
        // Assert UI update or toast message
    })
})

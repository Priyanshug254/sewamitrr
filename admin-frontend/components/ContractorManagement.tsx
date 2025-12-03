'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'

interface ContractorManagementProps {
    wardId: string
    cityId: string
    contractors: any[]
}

export default function ContractorManagement({ wardId, cityId, contractors: initialContractors }: ContractorManagementProps) {
    const [contractors, setContractors] = useState(initialContractors || [])
    const [showAddForm, setShowAddForm] = useState(false)
    const [loading, setLoading] = useState(false)
    const [formData, setFormData] = useState({
        email: '',
        fullName: '',
        phone: '',
        specializations: [] as string[],
    })

    const supabase = createClient()

    const handleAddContractor = async (e: React.FormEvent) => {
        e.preventDefault()
        setLoading(true)

        try {
            // Create auth user
            const { data: authData, error: authError } = await supabase.auth.admin.createUser({
                email: formData.email,
                password: 'TempPass2024', // Temporary password
                email_confirm: true,
                user_metadata: {
                    full_name: formData.fullName,
                    role: 'worker'
                }
            })

            if (authError) throw authError

            // Create contractor profile
            const { error: profileError } = await supabase
                .from('contractor_profiles')
                .insert({
                    user_id: authData.user.id,
                    specializations: formData.specializations,
                    phone: formData.phone,
                    rating: 0,
                    active_assignments: 0,
                    completed_assignments: 0
                })

            if (profileError) throw profileError

            // Refresh contractors list
            const { data: newContractors } = await supabase
                .from('users')
                .select('id, full_name, email, contractor_profiles(specializations, rating, active_assignments, completed_assignments, phone)')
                .eq('role', 'worker')
                .eq('city_id', cityId)
                .order('full_name')

            setContractors(newContractors || [])
            setShowAddForm(false)
            setFormData({ email: '', fullName: '', phone: '', specializations: [] })
            alert('Contractor added successfully! Temporary password: TempPass2024')
        } catch (error: any) {
            alert('Error adding contractor: ' + error.message)
        } finally {
            setLoading(false)
        }
    }

    const handleRemoveContractor = async (contractorId: string, contractorName: string) => {
        if (!confirm(`Are you sure you want to remove ${contractorName}?`)) return

        setLoading(true)
        try {
            // Delete contractor profile
            const { error: profileError } = await supabase
                .from('contractor_profiles')
                .delete()
                .eq('user_id', contractorId)

            if (profileError) throw profileError

            // Delete user
            const { error: userError } = await supabase.auth.admin.deleteUser(contractorId)
            if (userError) throw userError

            // Refresh list
            setContractors(contractors.filter(c => c.id !== contractorId))
            alert('Contractor removed successfully')
        } catch (error: any) {
            alert('Error removing contractor: ' + error.message)
        } finally {
            setLoading(false)
        }
    }

    const toggleSpecialization = (spec: string) => {
        setFormData(prev => ({
            ...prev,
            specializations: prev.specializations.includes(spec)
                ? prev.specializations.filter(s => s !== spec)
                : [...prev.specializations, spec]
        }))
    }

    const availableSpecializations = [
        'Water Supply',
        'Drainage',
        'Sanitation',
        'Pothole',
        'Street Light',
        'Garbage',
        'Other'
    ]

    return (
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <div className="flex items-center justify-between mb-6">
                <div>
                    <h2 className="text-xl font-bold text-gray-900 dark:text-white">Contractor Management</h2>
                    <p className="text-sm text-gray-600 dark:text-gray-400">Add or remove contractors for this ward</p>
                </div>
                <button
                    onClick={() => setShowAddForm(!showAddForm)}
                    className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
                    disabled={loading}
                >
                    {showAddForm ? 'Cancel' : '+ Add Contractor'}
                </button>
            </div>

            {/* Add Contractor Form */}
            {showAddForm && (
                <form onSubmit={handleAddContractor} className="mb-6 p-4 bg-gray-50 dark:bg-gray-700 rounded-lg">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                Full Name *
                            </label>
                            <input
                                type="text"
                                required
                                value={formData.fullName}
                                onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                Email *
                            </label>
                            <input
                                type="email"
                                required
                                value={formData.email}
                                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                Phone
                            </label>
                            <input
                                type="tel"
                                value={formData.phone}
                                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                            />
                        </div>
                    </div>

                    <div className="mb-4">
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            Specializations *
                        </label>
                        <div className="flex flex-wrap gap-2">
                            {availableSpecializations.map(spec => (
                                <button
                                    key={spec}
                                    type="button"
                                    onClick={() => toggleSpecialization(spec)}
                                    className={`px-3 py-1 rounded-full text-sm transition ${formData.specializations.includes(spec)
                                            ? 'bg-indigo-600 text-white'
                                            : 'bg-gray-200 dark:bg-gray-600 text-gray-700 dark:text-gray-300'
                                        }`}
                                >
                                    {spec}
                                </button>
                            ))}
                        </div>
                    </div>

                    <button
                        type="submit"
                        disabled={loading || formData.specializations.length === 0}
                        className="w-full px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition disabled:opacity-50"
                    >
                        {loading ? 'Adding...' : 'Add Contractor'}
                    </button>
                </form>
            )}

            {/* Contractors List */}
            <div className="space-y-3">
                {contractors.length === 0 ? (
                    <p className="text-center text-gray-500 dark:text-gray-400 py-8">No contractors added yet</p>
                ) : (
                    contractors.map((contractor: any) => (
                        <div
                            key={contractor.id}
                            className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-700 rounded-lg"
                        >
                            <div className="flex-1">
                                <h3 className="font-medium text-gray-900 dark:text-white">{contractor.full_name}</h3>
                                <p className="text-sm text-gray-600 dark:text-gray-400">{contractor.email}</p>
                                {contractor.contractor_profiles?.phone && (
                                    <p className="text-sm text-gray-600 dark:text-gray-400">
                                        📞 {contractor.contractor_profiles.phone}
                                    </p>
                                )}
                                <div className="flex flex-wrap gap-1 mt-2">
                                    {contractor.contractor_profiles?.specializations?.map((spec: string) => (
                                        <span
                                            key={spec}
                                            className="px-2 py-0.5 bg-indigo-100 dark:bg-indigo-900 text-indigo-800 dark:text-indigo-200 text-xs rounded"
                                        >
                                            {spec}
                                        </span>
                                    ))}
                                </div>
                            </div>
                            <div className="flex items-center gap-4">
                                <div className="text-right">
                                    <p className="text-sm text-gray-600 dark:text-gray-400">
                                        ⭐ {contractor.contractor_profiles?.rating || 0}
                                    </p>
                                    <p className="text-xs text-gray-500 dark:text-gray-400">
                                        {contractor.contractor_profiles?.active_assignments || 0} active
                                    </p>
                                </div>
                                <button
                                    onClick={() => handleRemoveContractor(contractor.id, contractor.full_name)}
                                    disabled={loading}
                                    className="px-3 py-1 bg-red-600 text-white text-sm rounded hover:bg-red-700 transition disabled:opacity-50"
                                >
                                    Remove
                                </button>
                            </div>
                        </div>
                    ))
                )}
            </div>
        </div>
    )
}

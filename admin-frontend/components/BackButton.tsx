'use client'

import { useRouter } from 'next/navigation'

export default function BackButton() {
    const router = useRouter()

    return (
        <button
            onClick={() => router.back()}
            className="h-10 w-10 bg-indigo-600 rounded-lg flex items-center justify-center hover:bg-indigo-700 transition"
        >
            <span className="text-xl font-bold text-white">←</span>
        </button>
    )
}

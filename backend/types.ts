/* eslint-disable */
// AUTO-GENERATED — DO NOT EDIT
// Run migrations to regenerate.

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.4"
  }
  public: {
    Tables: {
      challenges: {
        Row: {
          challenge_type: Database["public"]["Enums"]["challenge_type"]
          created_at: string
          description: string | null
          end_date: string
          goal: number
          goal_unit: string
          id: string
          name: string
          start_date: string
          status: Database["public"]["Enums"]["challenge_status"]
          tracking_type: Database["public"]["Enums"]["tracking_type"]
          updated_at: string
        }
        Insert: {
          challenge_type?: Database["public"]["Enums"]["challenge_type"]
          created_at?: string
          description?: string | null
          end_date: string
          goal?: number
          goal_unit?: string
          id?: string
          name: string
          start_date: string
          status?: Database["public"]["Enums"]["challenge_status"]
          tracking_type?: Database["public"]["Enums"]["tracking_type"]
          updated_at?: string
        }
        Update: {
          challenge_type?: Database["public"]["Enums"]["challenge_type"]
          created_at?: string
          description?: string | null
          end_date?: string
          goal?: number
          goal_unit?: string
          id?: string
          name?: string
          start_date?: string
          status?: Database["public"]["Enums"]["challenge_status"]
          tracking_type?: Database["public"]["Enums"]["tracking_type"]
          updated_at?: string
        }
        Relationships: []
      }
      clients: {
        Row: {
          active: boolean
          first_name: string
          id: number
          joined_at: string | null
          last_initial: string
          updated_at: string | null
        }
        Insert: {
          active?: boolean
          first_name: string
          id: number
          joined_at?: string | null
          last_initial: string
          updated_at?: string | null
        }
        Update: {
          active?: boolean
          first_name?: string
          id?: number
          joined_at?: string | null
          last_initial?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      feed_comments: {
        Row: {
          body: string
          client_id: number
          created_at: string
          id: string
          member_name: string
          post_id: string
        }
        Insert: {
          body: string
          client_id: number
          created_at?: string
          id?: string
          member_name: string
          post_id: string
        }
        Update: {
          body?: string
          client_id?: number
          created_at?: string
          id?: string
          member_name?: string
          post_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "feed_comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "feed_posts"
            referencedColumns: ["id"]
          },
        ]
      }
      feed_likes: {
        Row: {
          client_id: number
          created_at: string
          id: string
          member_name: string
          post_id: string
        }
        Insert: {
          client_id: number
          created_at?: string
          id?: string
          member_name?: string
          post_id: string
        }
        Update: {
          client_id?: number
          created_at?: string
          id?: string
          member_name?: string
          post_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "feed_likes_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "feed_posts"
            referencedColumns: ["id"]
          },
        ]
      }
      feed_posts: {
        Row: {
          calories: number | null
          caption: string | null
          class_datetime: string | null
          class_name: string | null
          class_type: string | null
          client_id: number
          created_at: string
          id: string
          member_name: string
          photo_url: string | null
          visit_key: string
        }
        Insert: {
          calories?: number | null
          caption?: string | null
          class_datetime?: string | null
          class_name?: string | null
          class_type?: string | null
          client_id: number
          created_at?: string
          id?: string
          member_name: string
          photo_url?: string | null
          visit_key: string
        }
        Update: {
          calories?: number | null
          caption?: string | null
          class_datetime?: string | null
          class_name?: string | null
          class_type?: string | null
          client_id?: number
          created_at?: string
          id?: string
          member_name?: string
          photo_url?: string | null
          visit_key?: string
        }
        Relationships: []
      }
      hall_of_fame: {
        Row: {
          challenge_description: string | null
          challenge_id: string
          challenge_name: string
          completed_at: string
          final_score: number
          id: string
          winner_name: string
        }
        Insert: {
          challenge_description?: string | null
          challenge_id: string
          challenge_name: string
          completed_at?: string
          final_score?: number
          id?: string
          winner_name: string
        }
        Update: {
          challenge_description?: string | null
          challenge_id?: string
          challenge_name?: string
          completed_at?: string
          final_score?: number
          id?: string
          winner_name?: string
        }
        Relationships: [
          {
            foreignKeyName: "hall_of_fame_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
        ]
      }
      leaderboard_snapshot: {
        Row: {
          client_id: number | null
          display_name: string
          generated_at: string | null
          id: string
          metadata: Json | null
          period: string
          rank: number
          value: number
        }
        Insert: {
          client_id?: number | null
          display_name: string
          generated_at?: string | null
          id?: string
          metadata?: Json | null
          period: string
          rank: number
          value: number
        }
        Update: {
          client_id?: number | null
          display_name?: string
          generated_at?: string | null
          id?: string
          metadata?: Json | null
          period?: string
          rank?: number
          value?: number
        }
        Relationships: [
          {
            foreignKeyName: "leaderboard_snapshot_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
        ]
      }
      member_profiles: {
        Row: {
          client_id: number
          member_name: string
          photo_url: string | null
          updated_at: string
        }
        Insert: {
          client_id: number
          member_name?: string
          photo_url?: string | null
          updated_at?: string
        }
        Update: {
          client_id?: number
          member_name?: string
          photo_url?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      oauth_states: {
        Row: {
          code_verifier: string | null
          created_at: string | null
          id: string
          state: string
        }
        Insert: {
          code_verifier?: string | null
          created_at?: string | null
          id?: string
          state: string
        }
        Update: {
          code_verifier?: string | null
          created_at?: string | null
          id?: string
          state?: string
        }
        Relationships: []
      }
      participants: {
        Row: {
          challenge_id: string
          current_score: number
          email: string | null
          enrolled_at: string
          id: string
          is_active: boolean
          mindbody_client_id: string | null
          name: string
          updated_at: string
        }
        Insert: {
          challenge_id: string
          current_score?: number
          email?: string | null
          enrolled_at?: string
          id?: string
          is_active?: boolean
          mindbody_client_id?: string | null
          name: string
          updated_at?: string
        }
        Update: {
          challenge_id?: string
          current_score?: number
          email?: string | null
          enrolled_at?: string
          id?: string
          is_active?: boolean
          mindbody_client_id?: string | null
          name?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "participants_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
        ]
      }
      progress_entries: {
        Row: {
          challenge_id: string
          id: string
          note: string | null
          participant_id: string
          points: number
          recorded_at: string
        }
        Insert: {
          challenge_id: string
          id?: string
          note?: string | null
          participant_id: string
          points?: number
          recorded_at?: string
        }
        Update: {
          challenge_id?: string
          id?: string
          note?: string | null
          participant_id?: string
          points?: number
          recorded_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "progress_entries_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "progress_entries_participant_id_fkey"
            columns: ["participant_id"]
            isOneToOne: false
            referencedRelation: "participants"
            referencedColumns: ["id"]
          },
        ]
      }
      sync_log: {
        Row: {
          error_message: string | null
          finished_at: string | null
          id: string
          job: string
          records: number | null
          started_at: string | null
          status: string | null
        }
        Insert: {
          error_message?: string | null
          finished_at?: string | null
          id?: string
          job: string
          records?: number | null
          started_at?: string | null
          status?: string | null
        }
        Update: {
          error_message?: string | null
          finished_at?: string | null
          id?: string
          job?: string
          records?: number | null
          started_at?: string | null
          status?: string | null
        }
        Relationships: []
      }
      visits: {
        Row: {
          class_id: number | null
          class_name: string | null
          client_id: number
          created_at: string | null
          id: number
          signed_in: boolean
          visit_date: string
          visit_datetime: string | null
        }
        Insert: {
          class_id?: number | null
          class_name?: string | null
          client_id: number
          created_at?: string | null
          id: number
          signed_in?: boolean
          visit_date: string
          visit_datetime?: string | null
        }
        Update: {
          class_id?: number | null
          class_name?: string | null
          client_id?: number
          created_at?: string | null
          id?: number
          signed_in?: boolean
          visit_date?: string
          visit_datetime?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "visits_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      publish_feed_posts: { Args: never; Returns: number }
    }
    Enums: {
      challenge_status: "draft" | "active" | "completed"
      challenge_type: "attendance" | "referrals" | "points" | "streaks"
      tracking_type: "manual" | "mindbody"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      challenge_status: ["draft", "active", "completed"],
      challenge_type: ["attendance", "referrals", "points", "streaks"],
      tracking_type: ["manual", "mindbody"],
    },
  },
} as const

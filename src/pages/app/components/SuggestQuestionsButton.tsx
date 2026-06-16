import { Button } from "@/components";
import { MessageCircleQuestionIcon } from "lucide-react";

// Prompt sent through the system-audio path (handleQuickActionClick), so the
// model receives the full meeting transcript as conversation history and
// returns questions the user can ask the other party. The answer shows up in
// the speech results panel like any other quick action.
const QUESTIONS_PROMPT =
  "На основе разговора сформулируй 3–5 вопросов, которые я могу задать " +
  "собеседнику прямо сейчас. Выведи только нумерованный список вопросов, " +
  "без вступлений и пояснений.";

export const SuggestQuestionsButton = ({
  onAsk,
  disabled,
}: {
  onAsk: (prompt: string) => void | Promise<void>;
  disabled?: boolean;
}) => {
  return (
    <Button
      size="sm"
      variant="outline"
      onClick={() => onAsk(QUESTIONS_PROMPT)}
      disabled={disabled}
      className="h-6 text-[10px] gap-1 px-2"
      title="Предложить вопросы собеседнику по текущему разговору"
    >
      <MessageCircleQuestionIcon className="w-3 h-3" />
      Generate questions
    </Button>
  );
};

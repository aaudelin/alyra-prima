import { BaseError } from "wagmi";

export default function ErrorComponent({ error }: { error: BaseError }) {
  return (
    <div className="p-4 border border-red-500 rounded-lg bg-red-50">
      <h3 className="text-lg font-semibold text-red-700">Error calling Prima contract</h3>
      <p className="text-red-600 mt-1">{error.shortMessage || error.message}</p>
    </div>
  );
}

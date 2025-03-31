import Link from "next/link";
import "../globals.css";

const Navbar = () => {
  return (
    <div className="p-2 h-screen w-64">
      <nav className="flex flex-col p-4 bg-primary text-primary-foreground rounded-lg h-full">
        {/* Logo section */}
        <div className="py-8">
          <Link href="/">
            <h1 className="text-2xl font-bold text-center">Prima</h1>
          </Link>
        </div>

        {/* Navigation section */}
        <div className="flex-1">
          <div className="space-y-6">
            {/* Créances section */}
            <div className="space-y-2">
              <h2 className="text-lg font-semibold">Créances</h2>
              <div className="pl-4 flex flex-col">
                <Link href="/claims/new">Nouvelle créance</Link>
                <Link href="/claims">Mes créances</Link>
              </div>
            </div>

            {/* Investissements section */}
            <div className="space-y-2">
              <h2 className="text-lg font-semibold">Investissements</h2>
              <div className="pl-4 flex flex-col">
                <Link href="/invest">Investir</Link>
                <Link href="/investments">Mes investissements</Link>
              </div>
            </div>

            {/* Paiements section */}
            <div className="space-y-2">
              <h2 className="text-lg font-semibold">Paiements</h2>
              <div className="pl-4 flex flex-col">
                <Link href="/payments/upcoming">Paiements à venir</Link>
                <Link href="/payments/completed">Paiements terminés</Link>
              </div>
            </div>
          </div>
        </div>

      </nav>
    </div>
  );
};

export default Navbar;

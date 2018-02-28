local pubchem = {}

function pubchem.scroll(splash)
    splash:runjs([[
        function () {
            $("html,body").animate({scrollTop: $("#Pharmacology-and-Biochemistry").offset().top}, 250);
            $("html,body").animate({scrollTop: $("#Absoption-Distribution-and-Excretion").offset().top}, 250);
            $("html,body").animate({scrollTop: $("#Metabolism-Metabolites").offset().top}, 250);
            $("html,body").animate({scrollTop: $("#Biologial-Half-Life").offset().top}, 250);
            $("html,body").animate({scrollTop: $("#").offset().top}, 250);
        }
        ]])
end

return pubchem

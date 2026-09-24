<?php
namespace App\Http\Controllers;
use App\Models\Pound;
use Illuminate\Http\Request;
class PoundController extends Controller
{
    public function index() { $pounds=Pound::withCount('missions')->orderBy('name')->paginate(15); return view('pounds.index',compact('pounds')); }
    public function create() { return view('pounds.form',['pound'=>new Pound()]); }
    public function store(Request $request) { $data=$this->validated($request); $data['created_by']=$request->user()->id; Pound::create($data); return redirect()->route('pounds.index')->with('success','Fourrière créée.'); }
    public function show(Pound $pound) { $pound->loadCount('missions'); return view('pounds.show',compact('pound')); }
    public function edit(Pound $pound) { return view('pounds.form',compact('pound')); }
    public function update(Request $request,Pound $pound) { $pound->update($this->validated($request)); return redirect()->route('pounds.show',$pound)->with('success','Fourrière modifiée.'); }
    public function destroy(Pound $pound) { if($pound->missions()->exists()) return back()->with('error','Cette fourrière est utilisée par une mission.'); $pound->delete(); return redirect()->route('pounds.index')->with('success','Fourrière supprimée.'); }
    private function validated(Request $request): array { $data=$request->validate(['name'=>['required','string','max:255'],'department'=>['nullable','string','max:255'],'latitude'=>['required','numeric','between:-90,90'],'longitude'=>['required','numeric','between:-180,180'],'geofence'=>['required','json']]); $data['geofence']=json_decode($data['geofence'],true,512,JSON_THROW_ON_ERROR); $data['geofence_margin_meters']=500; return $data; }
}

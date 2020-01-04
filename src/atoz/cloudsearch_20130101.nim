
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudSearch
## version: 2013-01-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudSearch Configuration Service</fullname> <p>You use the Amazon CloudSearch configuration service to create, configure, and manage search domains. Configuration service requests are submitted using the AWS Query protocol. AWS Query requests are HTTP or HTTPS requests submitted via HTTP GET or POST with a query parameter named Action.</p> <p>The endpoint for configuration service requests is region-specific: cloudsearch.<i>region</i>.amazonaws.com. For example, cloudsearch.us-east-1.amazonaws.com. For a current list of supported regions and endpoints, see <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html#cloudsearch_region" target="_blank">Regions and Endpoints</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudsearch/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
                           "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
                           "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com", "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com", "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
                           "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
                           "us-east-1": "cloudsearch.us-east-1.amazonaws.com", "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com", "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com", "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
                           "us-west-1": "cloudsearch.us-west-1.amazonaws.com", "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com", "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
                           "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com", "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com", "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
      "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
      "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
      "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
      "us-east-1": "cloudsearch.us-east-1.amazonaws.com",
      "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com",
      "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
      "us-west-1": "cloudsearch.us-west-1.amazonaws.com",
      "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com",
      "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
      "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cloudsearch"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostBuildSuggesters_601998 = ref object of OpenApiRestCall_601389
proc url_PostBuildSuggesters_602000(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostBuildSuggesters_601999(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602001 = query.getOrDefault("Action")
  valid_602001 = validateParameter(valid_602001, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_602001 != nil:
    section.add "Action", valid_602001
  var valid_602002 = query.getOrDefault("Version")
  valid_602002 = validateParameter(valid_602002, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602002 != nil:
    section.add "Version", valid_602002
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602003 = header.getOrDefault("X-Amz-Signature")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Signature", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Content-Sha256", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Date")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Date", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Credential")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Credential", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Security-Token")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Security-Token", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Algorithm")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Algorithm", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-SignedHeaders", valid_602009
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602010 = formData.getOrDefault("DomainName")
  valid_602010 = validateParameter(valid_602010, JString, required = true,
                                 default = nil)
  if valid_602010 != nil:
    section.add "DomainName", valid_602010
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602011: Call_PostBuildSuggesters_601998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602011.validator(path, query, header, formData, body)
  let scheme = call_602011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602011.url(scheme.get, call_602011.host, call_602011.base,
                         call_602011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602011, url, valid)

proc call*(call_602012: Call_PostBuildSuggesters_601998; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## postBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602013 = newJObject()
  var formData_602014 = newJObject()
  add(formData_602014, "DomainName", newJString(DomainName))
  add(query_602013, "Action", newJString(Action))
  add(query_602013, "Version", newJString(Version))
  result = call_602012.call(nil, query_602013, nil, formData_602014, nil)

var postBuildSuggesters* = Call_PostBuildSuggesters_601998(
    name: "postBuildSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_PostBuildSuggesters_601999, base: "/",
    url: url_PostBuildSuggesters_602000, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuildSuggesters_601727 = ref object of OpenApiRestCall_601389
proc url_GetBuildSuggesters_601729(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBuildSuggesters_601728(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_601841 = query.getOrDefault("DomainName")
  valid_601841 = validateParameter(valid_601841, JString, required = true,
                                 default = nil)
  if valid_601841 != nil:
    section.add "DomainName", valid_601841
  var valid_601855 = query.getOrDefault("Action")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_601855 != nil:
    section.add "Action", valid_601855
  var valid_601856 = query.getOrDefault("Version")
  valid_601856 = validateParameter(valid_601856, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_601856 != nil:
    section.add "Version", valid_601856
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601857 = header.getOrDefault("X-Amz-Signature")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Signature", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Content-Sha256", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Date")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Date", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Credential")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Credential", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Security-Token")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Security-Token", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Algorithm")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Algorithm", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-SignedHeaders", valid_601863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601886: Call_GetBuildSuggesters_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601886.validator(path, query, header, formData, body)
  let scheme = call_601886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601886.url(scheme.get, call_601886.host, call_601886.base,
                         call_601886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601886, url, valid)

proc call*(call_601957: Call_GetBuildSuggesters_601727; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## getBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601958 = newJObject()
  add(query_601958, "DomainName", newJString(DomainName))
  add(query_601958, "Action", newJString(Action))
  add(query_601958, "Version", newJString(Version))
  result = call_601957.call(nil, query_601958, nil, nil, nil)

var getBuildSuggesters* = Call_GetBuildSuggesters_601727(
    name: "getBuildSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_GetBuildSuggesters_601728, base: "/",
    url: url_GetBuildSuggesters_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_602031 = ref object of OpenApiRestCall_601389
proc url_PostCreateDomain_602033(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDomain_602032(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602034 = query.getOrDefault("Action")
  valid_602034 = validateParameter(valid_602034, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_602034 != nil:
    section.add "Action", valid_602034
  var valid_602035 = query.getOrDefault("Version")
  valid_602035 = validateParameter(valid_602035, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602035 != nil:
    section.add "Version", valid_602035
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602036 = header.getOrDefault("X-Amz-Signature")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Signature", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Content-Sha256", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Date")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Date", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Credential")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Credential", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Security-Token")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Security-Token", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Algorithm")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Algorithm", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-SignedHeaders", valid_602042
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602043 = formData.getOrDefault("DomainName")
  valid_602043 = validateParameter(valid_602043, JString, required = true,
                                 default = nil)
  if valid_602043 != nil:
    section.add "DomainName", valid_602043
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602044: Call_PostCreateDomain_602031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602044.validator(path, query, header, formData, body)
  let scheme = call_602044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602044.url(scheme.get, call_602044.host, call_602044.base,
                         call_602044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602044, url, valid)

proc call*(call_602045: Call_PostCreateDomain_602031; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602046 = newJObject()
  var formData_602047 = newJObject()
  add(formData_602047, "DomainName", newJString(DomainName))
  add(query_602046, "Action", newJString(Action))
  add(query_602046, "Version", newJString(Version))
  result = call_602045.call(nil, query_602046, nil, formData_602047, nil)

var postCreateDomain* = Call_PostCreateDomain_602031(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_602032,
    base: "/", url: url_PostCreateDomain_602033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_602015 = ref object of OpenApiRestCall_601389
proc url_GetCreateDomain_602017(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDomain_602016(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602018 = query.getOrDefault("DomainName")
  valid_602018 = validateParameter(valid_602018, JString, required = true,
                                 default = nil)
  if valid_602018 != nil:
    section.add "DomainName", valid_602018
  var valid_602019 = query.getOrDefault("Action")
  valid_602019 = validateParameter(valid_602019, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_602019 != nil:
    section.add "Action", valid_602019
  var valid_602020 = query.getOrDefault("Version")
  valid_602020 = validateParameter(valid_602020, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602020 != nil:
    section.add "Version", valid_602020
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602021 = header.getOrDefault("X-Amz-Signature")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Signature", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Content-Sha256", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Date")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Date", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Credential")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Credential", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Security-Token")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Security-Token", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Algorithm")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Algorithm", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-SignedHeaders", valid_602027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602028: Call_GetCreateDomain_602015; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602028.validator(path, query, header, formData, body)
  let scheme = call_602028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602028.url(scheme.get, call_602028.host, call_602028.base,
                         call_602028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602028, url, valid)

proc call*(call_602029: Call_GetCreateDomain_602015; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602030 = newJObject()
  add(query_602030, "DomainName", newJString(DomainName))
  add(query_602030, "Action", newJString(Action))
  add(query_602030, "Version", newJString(Version))
  result = call_602029.call(nil, query_602030, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_602015(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_602016,
    base: "/", url: url_GetCreateDomain_602017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineAnalysisScheme_602067 = ref object of OpenApiRestCall_601389
proc url_PostDefineAnalysisScheme_602069(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineAnalysisScheme_602068(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602070 = query.getOrDefault("Action")
  valid_602070 = validateParameter(valid_602070, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_602070 != nil:
    section.add "Action", valid_602070
  var valid_602071 = query.getOrDefault("Version")
  valid_602071 = validateParameter(valid_602071, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602071 != nil:
    section.add "Version", valid_602071
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602072 = header.getOrDefault("X-Amz-Signature")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Signature", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Content-Sha256", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Date")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Date", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Credential")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Credential", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Security-Token")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Security-Token", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Algorithm")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Algorithm", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-SignedHeaders", valid_602078
  result.add "header", section
  ## parameters in `formData` object:
  ##   AnalysisScheme.AnalysisSchemeLanguage: JString
  ##                                        : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisScheme.AnalysisSchemeName: JString
  ##                                    : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   AnalysisScheme.AnalysisOptions: JString
  ##                                 : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  section = newJObject()
  var valid_602079 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_602079
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602080 = formData.getOrDefault("DomainName")
  valid_602080 = validateParameter(valid_602080, JString, required = true,
                                 default = nil)
  if valid_602080 != nil:
    section.add "DomainName", valid_602080
  var valid_602081 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_602081
  var valid_602082 = formData.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_602082
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_PostDefineAnalysisScheme_602067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_PostDefineAnalysisScheme_602067; DomainName: string;
          AnalysisSchemeAnalysisSchemeLanguage: string = "";
          AnalysisSchemeAnalysisSchemeName: string = "";
          Action: string = "DefineAnalysisScheme";
          AnalysisSchemeAnalysisOptions: string = ""; Version: string = "2013-01-01"): Recallable =
  ## postDefineAnalysisScheme
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   AnalysisSchemeAnalysisSchemeLanguage: string
  ##                                       : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeAnalysisSchemeName: string
  ##                                   : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Action: string (required)
  ##   AnalysisSchemeAnalysisOptions: string
  ##                                : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Version: string (required)
  var query_602085 = newJObject()
  var formData_602086 = newJObject()
  add(formData_602086, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(formData_602086, "DomainName", newJString(DomainName))
  add(formData_602086, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_602085, "Action", newJString(Action))
  add(formData_602086, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(query_602085, "Version", newJString(Version))
  result = call_602084.call(nil, query_602085, nil, formData_602086, nil)

var postDefineAnalysisScheme* = Call_PostDefineAnalysisScheme_602067(
    name: "postDefineAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_PostDefineAnalysisScheme_602068, base: "/",
    url: url_PostDefineAnalysisScheme_602069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineAnalysisScheme_602048 = ref object of OpenApiRestCall_601389
proc url_GetDefineAnalysisScheme_602050(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineAnalysisScheme_602049(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisScheme.AnalysisSchemeName: JString
  ##                                    : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   AnalysisScheme.AnalysisOptions: JString
  ##                                 : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Action: JString (required)
  ##   AnalysisScheme.AnalysisSchemeLanguage: JString
  ##                                        : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602051 = query.getOrDefault("DomainName")
  valid_602051 = validateParameter(valid_602051, JString, required = true,
                                 default = nil)
  if valid_602051 != nil:
    section.add "DomainName", valid_602051
  var valid_602052 = query.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_602052
  var valid_602053 = query.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_602053
  var valid_602054 = query.getOrDefault("Action")
  valid_602054 = validateParameter(valid_602054, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_602054 != nil:
    section.add "Action", valid_602054
  var valid_602055 = query.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_602055
  var valid_602056 = query.getOrDefault("Version")
  valid_602056 = validateParameter(valid_602056, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602056 != nil:
    section.add "Version", valid_602056
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602057 = header.getOrDefault("X-Amz-Signature")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Signature", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Content-Sha256", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-Date")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Date", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Credential")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Credential", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Security-Token")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Security-Token", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Algorithm")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Algorithm", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-SignedHeaders", valid_602063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602064: Call_GetDefineAnalysisScheme_602048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602064.validator(path, query, header, formData, body)
  let scheme = call_602064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602064.url(scheme.get, call_602064.host, call_602064.base,
                         call_602064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602064, url, valid)

proc call*(call_602065: Call_GetDefineAnalysisScheme_602048; DomainName: string;
          AnalysisSchemeAnalysisSchemeName: string = "";
          AnalysisSchemeAnalysisOptions: string = "";
          Action: string = "DefineAnalysisScheme";
          AnalysisSchemeAnalysisSchemeLanguage: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## getDefineAnalysisScheme
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeAnalysisSchemeName: string
  ##                                   : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   AnalysisSchemeAnalysisOptions: string
  ##                                : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Action: string (required)
  ##   AnalysisSchemeAnalysisSchemeLanguage: string
  ##                                       : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Version: string (required)
  var query_602066 = newJObject()
  add(query_602066, "DomainName", newJString(DomainName))
  add(query_602066, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_602066, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(query_602066, "Action", newJString(Action))
  add(query_602066, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_602066, "Version", newJString(Version))
  result = call_602065.call(nil, query_602066, nil, nil, nil)

var getDefineAnalysisScheme* = Call_GetDefineAnalysisScheme_602048(
    name: "getDefineAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_GetDefineAnalysisScheme_602049, base: "/",
    url: url_GetDefineAnalysisScheme_602050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineExpression_602105 = ref object of OpenApiRestCall_601389
proc url_PostDefineExpression_602107(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineExpression_602106(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602108 = query.getOrDefault("Action")
  valid_602108 = validateParameter(valid_602108, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_602108 != nil:
    section.add "Action", valid_602108
  var valid_602109 = query.getOrDefault("Version")
  valid_602109 = validateParameter(valid_602109, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602109 != nil:
    section.add "Version", valid_602109
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602110 = header.getOrDefault("X-Amz-Signature")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Signature", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Content-Sha256", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Date")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Date", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Credential")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Credential", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-Security-Token")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Security-Token", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Algorithm")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Algorithm", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-SignedHeaders", valid_602116
  result.add "header", section
  ## parameters in `formData` object:
  ##   Expression.ExpressionName: JString
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Expression.ExpressionValue: JString
  ##                             : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_602117 = formData.getOrDefault("Expression.ExpressionName")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "Expression.ExpressionName", valid_602117
  var valid_602118 = formData.getOrDefault("Expression.ExpressionValue")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "Expression.ExpressionValue", valid_602118
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602119 = formData.getOrDefault("DomainName")
  valid_602119 = validateParameter(valid_602119, JString, required = true,
                                 default = nil)
  if valid_602119 != nil:
    section.add "DomainName", valid_602119
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602120: Call_PostDefineExpression_602105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602120.validator(path, query, header, formData, body)
  let scheme = call_602120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602120.url(scheme.get, call_602120.host, call_602120.base,
                         call_602120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602120, url, valid)

proc call*(call_602121: Call_PostDefineExpression_602105; DomainName: string;
          ExpressionExpressionName: string = "";
          ExpressionExpressionValue: string = "";
          Action: string = "DefineExpression"; Version: string = "2013-01-01"): Recallable =
  ## postDefineExpression
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   ExpressionExpressionName: string
  ##                           : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   ExpressionExpressionValue: string
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602122 = newJObject()
  var formData_602123 = newJObject()
  add(formData_602123, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(formData_602123, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(formData_602123, "DomainName", newJString(DomainName))
  add(query_602122, "Action", newJString(Action))
  add(query_602122, "Version", newJString(Version))
  result = call_602121.call(nil, query_602122, nil, formData_602123, nil)

var postDefineExpression* = Call_PostDefineExpression_602105(
    name: "postDefineExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_PostDefineExpression_602106, base: "/",
    url: url_PostDefineExpression_602107, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineExpression_602087 = ref object of OpenApiRestCall_601389
proc url_GetDefineExpression_602089(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineExpression_602088(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Expression.ExpressionValue: JString
  ##                             : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Action: JString (required)
  ##   Expression.ExpressionName: JString
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602090 = query.getOrDefault("DomainName")
  valid_602090 = validateParameter(valid_602090, JString, required = true,
                                 default = nil)
  if valid_602090 != nil:
    section.add "DomainName", valid_602090
  var valid_602091 = query.getOrDefault("Expression.ExpressionValue")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "Expression.ExpressionValue", valid_602091
  var valid_602092 = query.getOrDefault("Action")
  valid_602092 = validateParameter(valid_602092, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_602092 != nil:
    section.add "Action", valid_602092
  var valid_602093 = query.getOrDefault("Expression.ExpressionName")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "Expression.ExpressionName", valid_602093
  var valid_602094 = query.getOrDefault("Version")
  valid_602094 = validateParameter(valid_602094, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602094 != nil:
    section.add "Version", valid_602094
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602095 = header.getOrDefault("X-Amz-Signature")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Signature", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Content-Sha256", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Date")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Date", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Credential")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Credential", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Security-Token")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Security-Token", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Algorithm")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Algorithm", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-SignedHeaders", valid_602101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602102: Call_GetDefineExpression_602087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602102.validator(path, query, header, formData, body)
  let scheme = call_602102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602102.url(scheme.get, call_602102.host, call_602102.base,
                         call_602102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602102, url, valid)

proc call*(call_602103: Call_GetDefineExpression_602087; DomainName: string;
          ExpressionExpressionValue: string = "";
          Action: string = "DefineExpression";
          ExpressionExpressionName: string = ""; Version: string = "2013-01-01"): Recallable =
  ## getDefineExpression
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ExpressionExpressionValue: string
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Action: string (required)
  ##   ExpressionExpressionName: string
  ##                           : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Version: string (required)
  var query_602104 = newJObject()
  add(query_602104, "DomainName", newJString(DomainName))
  add(query_602104, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_602104, "Action", newJString(Action))
  add(query_602104, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(query_602104, "Version", newJString(Version))
  result = call_602103.call(nil, query_602104, nil, nil, nil)

var getDefineExpression* = Call_GetDefineExpression_602087(
    name: "getDefineExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_GetDefineExpression_602088, base: "/",
    url: url_GetDefineExpression_602089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_602153 = ref object of OpenApiRestCall_601389
proc url_PostDefineIndexField_602155(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineIndexField_602154(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602156 = query.getOrDefault("Action")
  valid_602156 = validateParameter(valid_602156, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_602156 != nil:
    section.add "Action", valid_602156
  var valid_602157 = query.getOrDefault("Version")
  valid_602157 = validateParameter(valid_602157, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602157 != nil:
    section.add "Version", valid_602157
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602158 = header.getOrDefault("X-Amz-Signature")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Signature", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Content-Sha256", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Date")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Date", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Credential")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Credential", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Security-Token")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Security-Token", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Algorithm")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Algorithm", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-SignedHeaders", valid_602164
  result.add "header", section
  ## parameters in `formData` object:
  ##   IndexField.IntOptions: JString
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.TextArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LatLonOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralArrayOptions: JString
  ##                                 : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldType: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexField.TextOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IntArrayOptions: JString
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralOptions: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldName: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexField.DateOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DateArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleArrayOptions: JString
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  section = newJObject()
  var valid_602165 = formData.getOrDefault("IndexField.IntOptions")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "IndexField.IntOptions", valid_602165
  var valid_602166 = formData.getOrDefault("IndexField.TextArrayOptions")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "IndexField.TextArrayOptions", valid_602166
  var valid_602167 = formData.getOrDefault("IndexField.DoubleOptions")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "IndexField.DoubleOptions", valid_602167
  var valid_602168 = formData.getOrDefault("IndexField.LatLonOptions")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "IndexField.LatLonOptions", valid_602168
  var valid_602169 = formData.getOrDefault("IndexField.LiteralArrayOptions")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_602169
  var valid_602170 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "IndexField.IndexFieldType", valid_602170
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602171 = formData.getOrDefault("DomainName")
  valid_602171 = validateParameter(valid_602171, JString, required = true,
                                 default = nil)
  if valid_602171 != nil:
    section.add "DomainName", valid_602171
  var valid_602172 = formData.getOrDefault("IndexField.TextOptions")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "IndexField.TextOptions", valid_602172
  var valid_602173 = formData.getOrDefault("IndexField.IntArrayOptions")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "IndexField.IntArrayOptions", valid_602173
  var valid_602174 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "IndexField.LiteralOptions", valid_602174
  var valid_602175 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "IndexField.IndexFieldName", valid_602175
  var valid_602176 = formData.getOrDefault("IndexField.DateOptions")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "IndexField.DateOptions", valid_602176
  var valid_602177 = formData.getOrDefault("IndexField.DateArrayOptions")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "IndexField.DateArrayOptions", valid_602177
  var valid_602178 = formData.getOrDefault("IndexField.DoubleArrayOptions")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_602178
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602179: Call_PostDefineIndexField_602153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_602179.validator(path, query, header, formData, body)
  let scheme = call_602179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602179.url(scheme.get, call_602179.host, call_602179.base,
                         call_602179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602179, url, valid)

proc call*(call_602180: Call_PostDefineIndexField_602153; DomainName: string;
          IndexFieldIntOptions: string = "";
          IndexFieldTextArrayOptions: string = "";
          IndexFieldDoubleOptions: string = "";
          IndexFieldLatLonOptions: string = "";
          IndexFieldLiteralArrayOptions: string = "";
          IndexFieldIndexFieldType: string = ""; IndexFieldTextOptions: string = "";
          IndexFieldIntArrayOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          Action: string = "DefineIndexField";
          IndexFieldIndexFieldName: string = ""; IndexFieldDateOptions: string = "";
          IndexFieldDateArrayOptions: string = ""; Version: string = "2013-01-01";
          IndexFieldDoubleArrayOptions: string = ""): Recallable =
  ## postDefineIndexField
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   IndexFieldIntOptions: string
  ##                       : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldTextArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDoubleOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLatLonOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralArrayOptions: string
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldType: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldTextOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIntArrayOptions: string
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralOptions: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Action: string (required)
  ##   IndexFieldIndexFieldName: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexFieldDateOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDateArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Version: string (required)
  ##   IndexFieldDoubleArrayOptions: string
  ##                               : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  var query_602181 = newJObject()
  var formData_602182 = newJObject()
  add(formData_602182, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(formData_602182, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(formData_602182, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(formData_602182, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(formData_602182, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(formData_602182, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(formData_602182, "DomainName", newJString(DomainName))
  add(formData_602182, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_602182, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(formData_602182, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_602181, "Action", newJString(Action))
  add(formData_602182, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(formData_602182, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(formData_602182, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_602181, "Version", newJString(Version))
  add(formData_602182, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  result = call_602180.call(nil, query_602181, nil, formData_602182, nil)

var postDefineIndexField* = Call_PostDefineIndexField_602153(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_602154, base: "/",
    url: url_PostDefineIndexField_602155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_602124 = ref object of OpenApiRestCall_601389
proc url_GetDefineIndexField_602126(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineIndexField_602125(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexField.TextOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralArrayOptions: JString
  ##                                 : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleArrayOptions: JString
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IntArrayOptions: JString
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldType: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexField.IndexFieldName: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexField.DoubleOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.TextArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Action: JString (required)
  ##   IndexField.DateOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralOptions: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IntOptions: JString
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Version: JString (required)
  ##   IndexField.DateArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LatLonOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  section = newJObject()
  var valid_602127 = query.getOrDefault("IndexField.TextOptions")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "IndexField.TextOptions", valid_602127
  var valid_602128 = query.getOrDefault("IndexField.LiteralArrayOptions")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_602128
  var valid_602129 = query.getOrDefault("IndexField.DoubleArrayOptions")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_602129
  var valid_602130 = query.getOrDefault("IndexField.IntArrayOptions")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "IndexField.IntArrayOptions", valid_602130
  var valid_602131 = query.getOrDefault("IndexField.IndexFieldType")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "IndexField.IndexFieldType", valid_602131
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602132 = query.getOrDefault("DomainName")
  valid_602132 = validateParameter(valid_602132, JString, required = true,
                                 default = nil)
  if valid_602132 != nil:
    section.add "DomainName", valid_602132
  var valid_602133 = query.getOrDefault("IndexField.IndexFieldName")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "IndexField.IndexFieldName", valid_602133
  var valid_602134 = query.getOrDefault("IndexField.DoubleOptions")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "IndexField.DoubleOptions", valid_602134
  var valid_602135 = query.getOrDefault("IndexField.TextArrayOptions")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "IndexField.TextArrayOptions", valid_602135
  var valid_602136 = query.getOrDefault("Action")
  valid_602136 = validateParameter(valid_602136, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_602136 != nil:
    section.add "Action", valid_602136
  var valid_602137 = query.getOrDefault("IndexField.DateOptions")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "IndexField.DateOptions", valid_602137
  var valid_602138 = query.getOrDefault("IndexField.LiteralOptions")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "IndexField.LiteralOptions", valid_602138
  var valid_602139 = query.getOrDefault("IndexField.IntOptions")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "IndexField.IntOptions", valid_602139
  var valid_602140 = query.getOrDefault("Version")
  valid_602140 = validateParameter(valid_602140, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602140 != nil:
    section.add "Version", valid_602140
  var valid_602141 = query.getOrDefault("IndexField.DateArrayOptions")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "IndexField.DateArrayOptions", valid_602141
  var valid_602142 = query.getOrDefault("IndexField.LatLonOptions")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "IndexField.LatLonOptions", valid_602142
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602143 = header.getOrDefault("X-Amz-Signature")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Signature", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Content-Sha256", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Date")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Date", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Credential")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Credential", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Security-Token")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Security-Token", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Algorithm")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Algorithm", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-SignedHeaders", valid_602149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602150: Call_GetDefineIndexField_602124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_602150.validator(path, query, header, formData, body)
  let scheme = call_602150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602150.url(scheme.get, call_602150.host, call_602150.base,
                         call_602150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602150, url, valid)

proc call*(call_602151: Call_GetDefineIndexField_602124; DomainName: string;
          IndexFieldTextOptions: string = "";
          IndexFieldLiteralArrayOptions: string = "";
          IndexFieldDoubleArrayOptions: string = "";
          IndexFieldIntArrayOptions: string = "";
          IndexFieldIndexFieldType: string = "";
          IndexFieldIndexFieldName: string = "";
          IndexFieldDoubleOptions: string = "";
          IndexFieldTextArrayOptions: string = "";
          Action: string = "DefineIndexField"; IndexFieldDateOptions: string = "";
          IndexFieldLiteralOptions: string = ""; IndexFieldIntOptions: string = "";
          Version: string = "2013-01-01"; IndexFieldDateArrayOptions: string = "";
          IndexFieldLatLonOptions: string = ""): Recallable =
  ## getDefineIndexField
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   IndexFieldTextOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralArrayOptions: string
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDoubleArrayOptions: string
  ##                               : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIntArrayOptions: string
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldType: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldIndexFieldName: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexFieldDoubleOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldTextArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Action: string (required)
  ##   IndexFieldDateOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralOptions: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIntOptions: string
  ##                       : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Version: string (required)
  ##   IndexFieldDateArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLatLonOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  var query_602152 = newJObject()
  add(query_602152, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_602152, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(query_602152, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(query_602152, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(query_602152, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_602152, "DomainName", newJString(DomainName))
  add(query_602152, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_602152, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(query_602152, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(query_602152, "Action", newJString(Action))
  add(query_602152, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(query_602152, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_602152, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(query_602152, "Version", newJString(Version))
  add(query_602152, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_602152, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  result = call_602151.call(nil, query_602152, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_602124(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_602125, base: "/",
    url: url_GetDefineIndexField_602126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineSuggester_602201 = ref object of OpenApiRestCall_601389
proc url_PostDefineSuggester_602203(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineSuggester_602202(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602204 = query.getOrDefault("Action")
  valid_602204 = validateParameter(valid_602204, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_602204 != nil:
    section.add "Action", valid_602204
  var valid_602205 = query.getOrDefault("Version")
  valid_602205 = validateParameter(valid_602205, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602205 != nil:
    section.add "Version", valid_602205
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602206 = header.getOrDefault("X-Amz-Signature")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Signature", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Content-Sha256", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Date")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Date", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Credential")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Credential", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Security-Token")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Security-Token", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Algorithm")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Algorithm", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-SignedHeaders", valid_602212
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Suggester.DocumentSuggesterOptions: JString
  ##                                     : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Suggester.SuggesterName: JString
  ##                          : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602213 = formData.getOrDefault("DomainName")
  valid_602213 = validateParameter(valid_602213, JString, required = true,
                                 default = nil)
  if valid_602213 != nil:
    section.add "DomainName", valid_602213
  var valid_602214 = formData.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_602214
  var valid_602215 = formData.getOrDefault("Suggester.SuggesterName")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "Suggester.SuggesterName", valid_602215
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602216: Call_PostDefineSuggester_602201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602216.validator(path, query, header, formData, body)
  let scheme = call_602216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602216.url(scheme.get, call_602216.host, call_602216.base,
                         call_602216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602216, url, valid)

proc call*(call_602217: Call_PostDefineSuggester_602201; DomainName: string;
          SuggesterDocumentSuggesterOptions: string = "";
          Action: string = "DefineSuggester"; SuggesterSuggesterName: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## postDefineSuggester
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterDocumentSuggesterOptions: string
  ##                                    : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Action: string (required)
  ##   SuggesterSuggesterName: string
  ##                         : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Version: string (required)
  var query_602218 = newJObject()
  var formData_602219 = newJObject()
  add(formData_602219, "DomainName", newJString(DomainName))
  add(formData_602219, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_602218, "Action", newJString(Action))
  add(formData_602219, "Suggester.SuggesterName",
      newJString(SuggesterSuggesterName))
  add(query_602218, "Version", newJString(Version))
  result = call_602217.call(nil, query_602218, nil, formData_602219, nil)

var postDefineSuggester* = Call_PostDefineSuggester_602201(
    name: "postDefineSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_PostDefineSuggester_602202, base: "/",
    url: url_PostDefineSuggester_602203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineSuggester_602183 = ref object of OpenApiRestCall_601389
proc url_GetDefineSuggester_602185(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineSuggester_602184(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Suggester.DocumentSuggesterOptions: JString
  ##                                     : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Action: JString (required)
  ##   Suggester.SuggesterName: JString
  ##                          : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602186 = query.getOrDefault("DomainName")
  valid_602186 = validateParameter(valid_602186, JString, required = true,
                                 default = nil)
  if valid_602186 != nil:
    section.add "DomainName", valid_602186
  var valid_602187 = query.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_602187
  var valid_602188 = query.getOrDefault("Action")
  valid_602188 = validateParameter(valid_602188, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_602188 != nil:
    section.add "Action", valid_602188
  var valid_602189 = query.getOrDefault("Suggester.SuggesterName")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "Suggester.SuggesterName", valid_602189
  var valid_602190 = query.getOrDefault("Version")
  valid_602190 = validateParameter(valid_602190, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602190 != nil:
    section.add "Version", valid_602190
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602191 = header.getOrDefault("X-Amz-Signature")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Signature", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Content-Sha256", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Date")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Date", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Credential")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Credential", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Security-Token")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Security-Token", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Algorithm")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Algorithm", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-SignedHeaders", valid_602197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602198: Call_GetDefineSuggester_602183; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602198.validator(path, query, header, formData, body)
  let scheme = call_602198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602198.url(scheme.get, call_602198.host, call_602198.base,
                         call_602198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602198, url, valid)

proc call*(call_602199: Call_GetDefineSuggester_602183; DomainName: string;
          SuggesterDocumentSuggesterOptions: string = "";
          Action: string = "DefineSuggester"; SuggesterSuggesterName: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## getDefineSuggester
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterDocumentSuggesterOptions: string
  ##                                    : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Action: string (required)
  ##   SuggesterSuggesterName: string
  ##                         : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Version: string (required)
  var query_602200 = newJObject()
  add(query_602200, "DomainName", newJString(DomainName))
  add(query_602200, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_602200, "Action", newJString(Action))
  add(query_602200, "Suggester.SuggesterName", newJString(SuggesterSuggesterName))
  add(query_602200, "Version", newJString(Version))
  result = call_602199.call(nil, query_602200, nil, nil, nil)

var getDefineSuggester* = Call_GetDefineSuggester_602183(
    name: "getDefineSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_GetDefineSuggester_602184, base: "/",
    url: url_GetDefineSuggester_602185, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnalysisScheme_602237 = ref object of OpenApiRestCall_601389
proc url_PostDeleteAnalysisScheme_602239(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteAnalysisScheme_602238(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602240 = query.getOrDefault("Action")
  valid_602240 = validateParameter(valid_602240, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_602240 != nil:
    section.add "Action", valid_602240
  var valid_602241 = query.getOrDefault("Version")
  valid_602241 = validateParameter(valid_602241, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602241 != nil:
    section.add "Version", valid_602241
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602242 = header.getOrDefault("X-Amz-Signature")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Signature", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Content-Sha256", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Date")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Date", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Credential")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Credential", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Security-Token")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Security-Token", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Algorithm")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Algorithm", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-SignedHeaders", valid_602248
  result.add "header", section
  ## parameters in `formData` object:
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AnalysisSchemeName` field"
  var valid_602249 = formData.getOrDefault("AnalysisSchemeName")
  valid_602249 = validateParameter(valid_602249, JString, required = true,
                                 default = nil)
  if valid_602249 != nil:
    section.add "AnalysisSchemeName", valid_602249
  var valid_602250 = formData.getOrDefault("DomainName")
  valid_602250 = validateParameter(valid_602250, JString, required = true,
                                 default = nil)
  if valid_602250 != nil:
    section.add "DomainName", valid_602250
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602251: Call_PostDeleteAnalysisScheme_602237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_602251.validator(path, query, header, formData, body)
  let scheme = call_602251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602251.url(scheme.get, call_602251.host, call_602251.base,
                         call_602251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602251, url, valid)

proc call*(call_602252: Call_PostDeleteAnalysisScheme_602237;
          AnalysisSchemeName: string; DomainName: string;
          Action: string = "DeleteAnalysisScheme"; Version: string = "2013-01-01"): Recallable =
  ## postDeleteAnalysisScheme
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   AnalysisSchemeName: string (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602253 = newJObject()
  var formData_602254 = newJObject()
  add(formData_602254, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(formData_602254, "DomainName", newJString(DomainName))
  add(query_602253, "Action", newJString(Action))
  add(query_602253, "Version", newJString(Version))
  result = call_602252.call(nil, query_602253, nil, formData_602254, nil)

var postDeleteAnalysisScheme* = Call_PostDeleteAnalysisScheme_602237(
    name: "postDeleteAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_PostDeleteAnalysisScheme_602238, base: "/",
    url: url_PostDeleteAnalysisScheme_602239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnalysisScheme_602220 = ref object of OpenApiRestCall_601389
proc url_GetDeleteAnalysisScheme_602222(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteAnalysisScheme_602221(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602223 = query.getOrDefault("DomainName")
  valid_602223 = validateParameter(valid_602223, JString, required = true,
                                 default = nil)
  if valid_602223 != nil:
    section.add "DomainName", valid_602223
  var valid_602224 = query.getOrDefault("Action")
  valid_602224 = validateParameter(valid_602224, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_602224 != nil:
    section.add "Action", valid_602224
  var valid_602225 = query.getOrDefault("AnalysisSchemeName")
  valid_602225 = validateParameter(valid_602225, JString, required = true,
                                 default = nil)
  if valid_602225 != nil:
    section.add "AnalysisSchemeName", valid_602225
  var valid_602226 = query.getOrDefault("Version")
  valid_602226 = validateParameter(valid_602226, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602226 != nil:
    section.add "Version", valid_602226
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602227 = header.getOrDefault("X-Amz-Signature")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Signature", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Content-Sha256", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Date")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Date", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Credential")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Credential", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Security-Token")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Security-Token", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Algorithm")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Algorithm", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-SignedHeaders", valid_602233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602234: Call_GetDeleteAnalysisScheme_602220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_602234.validator(path, query, header, formData, body)
  let scheme = call_602234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602234.url(scheme.get, call_602234.host, call_602234.base,
                         call_602234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602234, url, valid)

proc call*(call_602235: Call_GetDeleteAnalysisScheme_602220; DomainName: string;
          AnalysisSchemeName: string; Action: string = "DeleteAnalysisScheme";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteAnalysisScheme
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   AnalysisSchemeName: string (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Version: string (required)
  var query_602236 = newJObject()
  add(query_602236, "DomainName", newJString(DomainName))
  add(query_602236, "Action", newJString(Action))
  add(query_602236, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_602236, "Version", newJString(Version))
  result = call_602235.call(nil, query_602236, nil, nil, nil)

var getDeleteAnalysisScheme* = Call_GetDeleteAnalysisScheme_602220(
    name: "getDeleteAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_GetDeleteAnalysisScheme_602221, base: "/",
    url: url_GetDeleteAnalysisScheme_602222, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_602271 = ref object of OpenApiRestCall_601389
proc url_PostDeleteDomain_602273(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDomain_602272(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602274 = query.getOrDefault("Action")
  valid_602274 = validateParameter(valid_602274, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_602274 != nil:
    section.add "Action", valid_602274
  var valid_602275 = query.getOrDefault("Version")
  valid_602275 = validateParameter(valid_602275, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602275 != nil:
    section.add "Version", valid_602275
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602276 = header.getOrDefault("X-Amz-Signature")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Signature", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Content-Sha256", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Date")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Date", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-Credential")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Credential", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Security-Token")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Security-Token", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Algorithm")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Algorithm", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-SignedHeaders", valid_602282
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602283 = formData.getOrDefault("DomainName")
  valid_602283 = validateParameter(valid_602283, JString, required = true,
                                 default = nil)
  if valid_602283 != nil:
    section.add "DomainName", valid_602283
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602284: Call_PostDeleteDomain_602271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_602284.validator(path, query, header, formData, body)
  let scheme = call_602284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602284.url(scheme.get, call_602284.host, call_602284.base,
                         call_602284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602284, url, valid)

proc call*(call_602285: Call_PostDeleteDomain_602271; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602286 = newJObject()
  var formData_602287 = newJObject()
  add(formData_602287, "DomainName", newJString(DomainName))
  add(query_602286, "Action", newJString(Action))
  add(query_602286, "Version", newJString(Version))
  result = call_602285.call(nil, query_602286, nil, formData_602287, nil)

var postDeleteDomain* = Call_PostDeleteDomain_602271(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_602272,
    base: "/", url: url_PostDeleteDomain_602273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_602255 = ref object of OpenApiRestCall_601389
proc url_GetDeleteDomain_602257(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDomain_602256(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602258 = query.getOrDefault("DomainName")
  valid_602258 = validateParameter(valid_602258, JString, required = true,
                                 default = nil)
  if valid_602258 != nil:
    section.add "DomainName", valid_602258
  var valid_602259 = query.getOrDefault("Action")
  valid_602259 = validateParameter(valid_602259, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_602259 != nil:
    section.add "Action", valid_602259
  var valid_602260 = query.getOrDefault("Version")
  valid_602260 = validateParameter(valid_602260, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602260 != nil:
    section.add "Version", valid_602260
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602261 = header.getOrDefault("X-Amz-Signature")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Signature", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Content-Sha256", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-Date")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Date", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Credential")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Credential", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-Security-Token")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Security-Token", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-Algorithm")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Algorithm", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-SignedHeaders", valid_602267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602268: Call_GetDeleteDomain_602255; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_602268.validator(path, query, header, formData, body)
  let scheme = call_602268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602268.url(scheme.get, call_602268.host, call_602268.base,
                         call_602268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602268, url, valid)

proc call*(call_602269: Call_GetDeleteDomain_602255; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602270 = newJObject()
  add(query_602270, "DomainName", newJString(DomainName))
  add(query_602270, "Action", newJString(Action))
  add(query_602270, "Version", newJString(Version))
  result = call_602269.call(nil, query_602270, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_602255(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_602256,
    base: "/", url: url_GetDeleteDomain_602257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteExpression_602305 = ref object of OpenApiRestCall_601389
proc url_PostDeleteExpression_602307(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteExpression_602306(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602308 = query.getOrDefault("Action")
  valid_602308 = validateParameter(valid_602308, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_602308 != nil:
    section.add "Action", valid_602308
  var valid_602309 = query.getOrDefault("Version")
  valid_602309 = validateParameter(valid_602309, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602309 != nil:
    section.add "Version", valid_602309
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602310 = header.getOrDefault("X-Amz-Signature")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Signature", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Content-Sha256", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Date")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Date", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Credential")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Credential", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Security-Token")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Security-Token", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Algorithm")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Algorithm", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-SignedHeaders", valid_602316
  result.add "header", section
  ## parameters in `formData` object:
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ExpressionName` field"
  var valid_602317 = formData.getOrDefault("ExpressionName")
  valid_602317 = validateParameter(valid_602317, JString, required = true,
                                 default = nil)
  if valid_602317 != nil:
    section.add "ExpressionName", valid_602317
  var valid_602318 = formData.getOrDefault("DomainName")
  valid_602318 = validateParameter(valid_602318, JString, required = true,
                                 default = nil)
  if valid_602318 != nil:
    section.add "DomainName", valid_602318
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602319: Call_PostDeleteExpression_602305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602319.validator(path, query, header, formData, body)
  let scheme = call_602319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602319.url(scheme.get, call_602319.host, call_602319.base,
                         call_602319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602319, url, valid)

proc call*(call_602320: Call_PostDeleteExpression_602305; ExpressionName: string;
          DomainName: string; Action: string = "DeleteExpression";
          Version: string = "2013-01-01"): Recallable =
  ## postDeleteExpression
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   ExpressionName: string (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602321 = newJObject()
  var formData_602322 = newJObject()
  add(formData_602322, "ExpressionName", newJString(ExpressionName))
  add(formData_602322, "DomainName", newJString(DomainName))
  add(query_602321, "Action", newJString(Action))
  add(query_602321, "Version", newJString(Version))
  result = call_602320.call(nil, query_602321, nil, formData_602322, nil)

var postDeleteExpression* = Call_PostDeleteExpression_602305(
    name: "postDeleteExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_PostDeleteExpression_602306, base: "/",
    url: url_PostDeleteExpression_602307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteExpression_602288 = ref object of OpenApiRestCall_601389
proc url_GetDeleteExpression_602290(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteExpression_602289(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ExpressionName` field"
  var valid_602291 = query.getOrDefault("ExpressionName")
  valid_602291 = validateParameter(valid_602291, JString, required = true,
                                 default = nil)
  if valid_602291 != nil:
    section.add "ExpressionName", valid_602291
  var valid_602292 = query.getOrDefault("DomainName")
  valid_602292 = validateParameter(valid_602292, JString, required = true,
                                 default = nil)
  if valid_602292 != nil:
    section.add "DomainName", valid_602292
  var valid_602293 = query.getOrDefault("Action")
  valid_602293 = validateParameter(valid_602293, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_602293 != nil:
    section.add "Action", valid_602293
  var valid_602294 = query.getOrDefault("Version")
  valid_602294 = validateParameter(valid_602294, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602294 != nil:
    section.add "Version", valid_602294
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602295 = header.getOrDefault("X-Amz-Signature")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Signature", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Content-Sha256", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Date")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Date", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Credential")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Credential", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Security-Token")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Security-Token", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Algorithm")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Algorithm", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-SignedHeaders", valid_602301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602302: Call_GetDeleteExpression_602288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602302.validator(path, query, header, formData, body)
  let scheme = call_602302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602302.url(scheme.get, call_602302.host, call_602302.base,
                         call_602302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602302, url, valid)

proc call*(call_602303: Call_GetDeleteExpression_602288; ExpressionName: string;
          DomainName: string; Action: string = "DeleteExpression";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteExpression
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   ExpressionName: string (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602304 = newJObject()
  add(query_602304, "ExpressionName", newJString(ExpressionName))
  add(query_602304, "DomainName", newJString(DomainName))
  add(query_602304, "Action", newJString(Action))
  add(query_602304, "Version", newJString(Version))
  result = call_602303.call(nil, query_602304, nil, nil, nil)

var getDeleteExpression* = Call_GetDeleteExpression_602288(
    name: "getDeleteExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_GetDeleteExpression_602289, base: "/",
    url: url_GetDeleteExpression_602290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_602340 = ref object of OpenApiRestCall_601389
proc url_PostDeleteIndexField_602342(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteIndexField_602341(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602343 = query.getOrDefault("Action")
  valid_602343 = validateParameter(valid_602343, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_602343 != nil:
    section.add "Action", valid_602343
  var valid_602344 = query.getOrDefault("Version")
  valid_602344 = validateParameter(valid_602344, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602344 != nil:
    section.add "Version", valid_602344
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602345 = header.getOrDefault("X-Amz-Signature")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Signature", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Content-Sha256", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Date")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Date", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Credential")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Credential", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Security-Token")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Security-Token", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Algorithm")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Algorithm", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-SignedHeaders", valid_602351
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602352 = formData.getOrDefault("DomainName")
  valid_602352 = validateParameter(valid_602352, JString, required = true,
                                 default = nil)
  if valid_602352 != nil:
    section.add "DomainName", valid_602352
  var valid_602353 = formData.getOrDefault("IndexFieldName")
  valid_602353 = validateParameter(valid_602353, JString, required = true,
                                 default = nil)
  if valid_602353 != nil:
    section.add "IndexFieldName", valid_602353
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602354: Call_PostDeleteIndexField_602340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602354.validator(path, query, header, formData, body)
  let scheme = call_602354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602354.url(scheme.get, call_602354.host, call_602354.base,
                         call_602354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602354, url, valid)

proc call*(call_602355: Call_PostDeleteIndexField_602340; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2013-01-01"): Recallable =
  ## postDeleteIndexField
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldName: string (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602356 = newJObject()
  var formData_602357 = newJObject()
  add(formData_602357, "DomainName", newJString(DomainName))
  add(formData_602357, "IndexFieldName", newJString(IndexFieldName))
  add(query_602356, "Action", newJString(Action))
  add(query_602356, "Version", newJString(Version))
  result = call_602355.call(nil, query_602356, nil, formData_602357, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_602340(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_602341, base: "/",
    url: url_PostDeleteIndexField_602342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_602323 = ref object of OpenApiRestCall_601389
proc url_GetDeleteIndexField_602325(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteIndexField_602324(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602326 = query.getOrDefault("DomainName")
  valid_602326 = validateParameter(valid_602326, JString, required = true,
                                 default = nil)
  if valid_602326 != nil:
    section.add "DomainName", valid_602326
  var valid_602327 = query.getOrDefault("Action")
  valid_602327 = validateParameter(valid_602327, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_602327 != nil:
    section.add "Action", valid_602327
  var valid_602328 = query.getOrDefault("IndexFieldName")
  valid_602328 = validateParameter(valid_602328, JString, required = true,
                                 default = nil)
  if valid_602328 != nil:
    section.add "IndexFieldName", valid_602328
  var valid_602329 = query.getOrDefault("Version")
  valid_602329 = validateParameter(valid_602329, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602329 != nil:
    section.add "Version", valid_602329
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602330 = header.getOrDefault("X-Amz-Signature")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Signature", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Content-Sha256", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Date")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Date", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Credential")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Credential", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Security-Token")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Security-Token", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Algorithm")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Algorithm", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-SignedHeaders", valid_602336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602337: Call_GetDeleteIndexField_602323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602337.validator(path, query, header, formData, body)
  let scheme = call_602337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602337.url(scheme.get, call_602337.host, call_602337.base,
                         call_602337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602337, url, valid)

proc call*(call_602338: Call_GetDeleteIndexField_602323; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteIndexField
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   IndexFieldName: string (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  ##   Version: string (required)
  var query_602339 = newJObject()
  add(query_602339, "DomainName", newJString(DomainName))
  add(query_602339, "Action", newJString(Action))
  add(query_602339, "IndexFieldName", newJString(IndexFieldName))
  add(query_602339, "Version", newJString(Version))
  result = call_602338.call(nil, query_602339, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_602323(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_602324, base: "/",
    url: url_GetDeleteIndexField_602325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteSuggester_602375 = ref object of OpenApiRestCall_601389
proc url_PostDeleteSuggester_602377(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteSuggester_602376(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602378 = query.getOrDefault("Action")
  valid_602378 = validateParameter(valid_602378, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_602378 != nil:
    section.add "Action", valid_602378
  var valid_602379 = query.getOrDefault("Version")
  valid_602379 = validateParameter(valid_602379, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602379 != nil:
    section.add "Version", valid_602379
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602380 = header.getOrDefault("X-Amz-Signature")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Signature", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Content-Sha256", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Date")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Date", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Credential")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Credential", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Security-Token")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Security-Token", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Algorithm")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Algorithm", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-SignedHeaders", valid_602386
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602387 = formData.getOrDefault("DomainName")
  valid_602387 = validateParameter(valid_602387, JString, required = true,
                                 default = nil)
  if valid_602387 != nil:
    section.add "DomainName", valid_602387
  var valid_602388 = formData.getOrDefault("SuggesterName")
  valid_602388 = validateParameter(valid_602388, JString, required = true,
                                 default = nil)
  if valid_602388 != nil:
    section.add "SuggesterName", valid_602388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602389: Call_PostDeleteSuggester_602375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602389.validator(path, query, header, formData, body)
  let scheme = call_602389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602389.url(scheme.get, call_602389.host, call_602389.base,
                         call_602389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602389, url, valid)

proc call*(call_602390: Call_PostDeleteSuggester_602375; DomainName: string;
          SuggesterName: string; Action: string = "DeleteSuggester";
          Version: string = "2013-01-01"): Recallable =
  ## postDeleteSuggester
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterName: string (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602391 = newJObject()
  var formData_602392 = newJObject()
  add(formData_602392, "DomainName", newJString(DomainName))
  add(formData_602392, "SuggesterName", newJString(SuggesterName))
  add(query_602391, "Action", newJString(Action))
  add(query_602391, "Version", newJString(Version))
  result = call_602390.call(nil, query_602391, nil, formData_602392, nil)

var postDeleteSuggester* = Call_PostDeleteSuggester_602375(
    name: "postDeleteSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_PostDeleteSuggester_602376, base: "/",
    url: url_PostDeleteSuggester_602377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteSuggester_602358 = ref object of OpenApiRestCall_601389
proc url_GetDeleteSuggester_602360(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteSuggester_602359(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602361 = query.getOrDefault("DomainName")
  valid_602361 = validateParameter(valid_602361, JString, required = true,
                                 default = nil)
  if valid_602361 != nil:
    section.add "DomainName", valid_602361
  var valid_602362 = query.getOrDefault("Action")
  valid_602362 = validateParameter(valid_602362, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_602362 != nil:
    section.add "Action", valid_602362
  var valid_602363 = query.getOrDefault("Version")
  valid_602363 = validateParameter(valid_602363, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602363 != nil:
    section.add "Version", valid_602363
  var valid_602364 = query.getOrDefault("SuggesterName")
  valid_602364 = validateParameter(valid_602364, JString, required = true,
                                 default = nil)
  if valid_602364 != nil:
    section.add "SuggesterName", valid_602364
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602365 = header.getOrDefault("X-Amz-Signature")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Signature", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Content-Sha256", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Date")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Date", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Credential")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Credential", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Security-Token")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Security-Token", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Algorithm")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Algorithm", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-SignedHeaders", valid_602371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602372: Call_GetDeleteSuggester_602358; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602372.validator(path, query, header, formData, body)
  let scheme = call_602372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602372.url(scheme.get, call_602372.host, call_602372.base,
                         call_602372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602372, url, valid)

proc call*(call_602373: Call_GetDeleteSuggester_602358; DomainName: string;
          SuggesterName: string; Action: string = "DeleteSuggester";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteSuggester
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SuggesterName: string (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  var query_602374 = newJObject()
  add(query_602374, "DomainName", newJString(DomainName))
  add(query_602374, "Action", newJString(Action))
  add(query_602374, "Version", newJString(Version))
  add(query_602374, "SuggesterName", newJString(SuggesterName))
  result = call_602373.call(nil, query_602374, nil, nil, nil)

var getDeleteSuggester* = Call_GetDeleteSuggester_602358(
    name: "getDeleteSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_GetDeleteSuggester_602359, base: "/",
    url: url_GetDeleteSuggester_602360, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnalysisSchemes_602411 = ref object of OpenApiRestCall_601389
proc url_PostDescribeAnalysisSchemes_602413(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAnalysisSchemes_602412(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602414 = query.getOrDefault("Action")
  valid_602414 = validateParameter(valid_602414, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_602414 != nil:
    section.add "Action", valid_602414
  var valid_602415 = query.getOrDefault("Version")
  valid_602415 = validateParameter(valid_602415, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602415 != nil:
    section.add "Version", valid_602415
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602416 = header.getOrDefault("X-Amz-Signature")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Signature", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Content-Sha256", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Date")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Date", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-Credential")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-Credential", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-Security-Token")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Security-Token", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Algorithm")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Algorithm", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-SignedHeaders", valid_602422
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  section = newJObject()
  var valid_602423 = formData.getOrDefault("Deployed")
  valid_602423 = validateParameter(valid_602423, JBool, required = false, default = nil)
  if valid_602423 != nil:
    section.add "Deployed", valid_602423
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602424 = formData.getOrDefault("DomainName")
  valid_602424 = validateParameter(valid_602424, JString, required = true,
                                 default = nil)
  if valid_602424 != nil:
    section.add "DomainName", valid_602424
  var valid_602425 = formData.getOrDefault("AnalysisSchemeNames")
  valid_602425 = validateParameter(valid_602425, JArray, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "AnalysisSchemeNames", valid_602425
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602426: Call_PostDescribeAnalysisSchemes_602411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602426.validator(path, query, header, formData, body)
  let scheme = call_602426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602426.url(scheme.get, call_602426.host, call_602426.base,
                         call_602426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602426, url, valid)

proc call*(call_602427: Call_PostDescribeAnalysisSchemes_602411;
          DomainName: string; Deployed: bool = false;
          AnalysisSchemeNames: JsonNode = nil;
          Action: string = "DescribeAnalysisSchemes"; Version: string = "2013-01-01"): Recallable =
  ## postDescribeAnalysisSchemes
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602428 = newJObject()
  var formData_602429 = newJObject()
  add(formData_602429, "Deployed", newJBool(Deployed))
  add(formData_602429, "DomainName", newJString(DomainName))
  if AnalysisSchemeNames != nil:
    formData_602429.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_602428, "Action", newJString(Action))
  add(query_602428, "Version", newJString(Version))
  result = call_602427.call(nil, query_602428, nil, formData_602429, nil)

var postDescribeAnalysisSchemes* = Call_PostDescribeAnalysisSchemes_602411(
    name: "postDescribeAnalysisSchemes", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_PostDescribeAnalysisSchemes_602412, base: "/",
    url: url_PostDescribeAnalysisSchemes_602413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnalysisSchemes_602393 = ref object of OpenApiRestCall_601389
proc url_GetDescribeAnalysisSchemes_602395(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAnalysisSchemes_602394(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602396 = query.getOrDefault("DomainName")
  valid_602396 = validateParameter(valid_602396, JString, required = true,
                                 default = nil)
  if valid_602396 != nil:
    section.add "DomainName", valid_602396
  var valid_602397 = query.getOrDefault("AnalysisSchemeNames")
  valid_602397 = validateParameter(valid_602397, JArray, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "AnalysisSchemeNames", valid_602397
  var valid_602398 = query.getOrDefault("Deployed")
  valid_602398 = validateParameter(valid_602398, JBool, required = false, default = nil)
  if valid_602398 != nil:
    section.add "Deployed", valid_602398
  var valid_602399 = query.getOrDefault("Action")
  valid_602399 = validateParameter(valid_602399, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_602399 != nil:
    section.add "Action", valid_602399
  var valid_602400 = query.getOrDefault("Version")
  valid_602400 = validateParameter(valid_602400, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602400 != nil:
    section.add "Version", valid_602400
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602401 = header.getOrDefault("X-Amz-Signature")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Signature", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Content-Sha256", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Date")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Date", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-Credential")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Credential", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Security-Token")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Security-Token", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Algorithm")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Algorithm", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-SignedHeaders", valid_602407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602408: Call_GetDescribeAnalysisSchemes_602393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602408.validator(path, query, header, formData, body)
  let scheme = call_602408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602408.url(scheme.get, call_602408.host, call_602408.base,
                         call_602408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602408, url, valid)

proc call*(call_602409: Call_GetDescribeAnalysisSchemes_602393; DomainName: string;
          AnalysisSchemeNames: JsonNode = nil; Deployed: bool = false;
          Action: string = "DescribeAnalysisSchemes"; Version: string = "2013-01-01"): Recallable =
  ## getDescribeAnalysisSchemes
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602410 = newJObject()
  add(query_602410, "DomainName", newJString(DomainName))
  if AnalysisSchemeNames != nil:
    query_602410.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_602410, "Deployed", newJBool(Deployed))
  add(query_602410, "Action", newJString(Action))
  add(query_602410, "Version", newJString(Version))
  result = call_602409.call(nil, query_602410, nil, nil, nil)

var getDescribeAnalysisSchemes* = Call_GetDescribeAnalysisSchemes_602393(
    name: "getDescribeAnalysisSchemes", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_GetDescribeAnalysisSchemes_602394, base: "/",
    url: url_GetDescribeAnalysisSchemes_602395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_602447 = ref object of OpenApiRestCall_601389
proc url_PostDescribeAvailabilityOptions_602449(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAvailabilityOptions_602448(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602450 = query.getOrDefault("Action")
  valid_602450 = validateParameter(valid_602450, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_602450 != nil:
    section.add "Action", valid_602450
  var valid_602451 = query.getOrDefault("Version")
  valid_602451 = validateParameter(valid_602451, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602451 != nil:
    section.add "Version", valid_602451
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602452 = header.getOrDefault("X-Amz-Signature")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Signature", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-Content-Sha256", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-Date")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Date", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Credential")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Credential", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-Security-Token")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-Security-Token", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-Algorithm")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Algorithm", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-SignedHeaders", valid_602458
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_602459 = formData.getOrDefault("Deployed")
  valid_602459 = validateParameter(valid_602459, JBool, required = false, default = nil)
  if valid_602459 != nil:
    section.add "Deployed", valid_602459
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602460 = formData.getOrDefault("DomainName")
  valid_602460 = validateParameter(valid_602460, JString, required = true,
                                 default = nil)
  if valid_602460 != nil:
    section.add "DomainName", valid_602460
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602461: Call_PostDescribeAvailabilityOptions_602447;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602461.validator(path, query, header, formData, body)
  let scheme = call_602461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602461.url(scheme.get, call_602461.host, call_602461.base,
                         call_602461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602461, url, valid)

proc call*(call_602462: Call_PostDescribeAvailabilityOptions_602447;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602463 = newJObject()
  var formData_602464 = newJObject()
  add(formData_602464, "Deployed", newJBool(Deployed))
  add(formData_602464, "DomainName", newJString(DomainName))
  add(query_602463, "Action", newJString(Action))
  add(query_602463, "Version", newJString(Version))
  result = call_602462.call(nil, query_602463, nil, formData_602464, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_602447(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_602448, base: "/",
    url: url_PostDescribeAvailabilityOptions_602449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_602430 = ref object of OpenApiRestCall_601389
proc url_GetDescribeAvailabilityOptions_602432(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAvailabilityOptions_602431(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602433 = query.getOrDefault("DomainName")
  valid_602433 = validateParameter(valid_602433, JString, required = true,
                                 default = nil)
  if valid_602433 != nil:
    section.add "DomainName", valid_602433
  var valid_602434 = query.getOrDefault("Deployed")
  valid_602434 = validateParameter(valid_602434, JBool, required = false, default = nil)
  if valid_602434 != nil:
    section.add "Deployed", valid_602434
  var valid_602435 = query.getOrDefault("Action")
  valid_602435 = validateParameter(valid_602435, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_602435 != nil:
    section.add "Action", valid_602435
  var valid_602436 = query.getOrDefault("Version")
  valid_602436 = validateParameter(valid_602436, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602436 != nil:
    section.add "Version", valid_602436
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602437 = header.getOrDefault("X-Amz-Signature")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Signature", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Content-Sha256", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-Date")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-Date", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-Credential")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Credential", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-Security-Token")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Security-Token", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Algorithm")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Algorithm", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-SignedHeaders", valid_602443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602444: Call_GetDescribeAvailabilityOptions_602430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602444.validator(path, query, header, formData, body)
  let scheme = call_602444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602444.url(scheme.get, call_602444.host, call_602444.base,
                         call_602444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602444, url, valid)

proc call*(call_602445: Call_GetDescribeAvailabilityOptions_602430;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602446 = newJObject()
  add(query_602446, "DomainName", newJString(DomainName))
  add(query_602446, "Deployed", newJBool(Deployed))
  add(query_602446, "Action", newJString(Action))
  add(query_602446, "Version", newJString(Version))
  result = call_602445.call(nil, query_602446, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_602430(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_602431, base: "/",
    url: url_GetDescribeAvailabilityOptions_602432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomainEndpointOptions_602482 = ref object of OpenApiRestCall_601389
proc url_PostDescribeDomainEndpointOptions_602484(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDomainEndpointOptions_602483(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602485 = query.getOrDefault("Action")
  valid_602485 = validateParameter(valid_602485, JString, required = true, default = newJString(
      "DescribeDomainEndpointOptions"))
  if valid_602485 != nil:
    section.add "Action", valid_602485
  var valid_602486 = query.getOrDefault("Version")
  valid_602486 = validateParameter(valid_602486, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602486 != nil:
    section.add "Version", valid_602486
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602487 = header.getOrDefault("X-Amz-Signature")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-Signature", valid_602487
  var valid_602488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-Content-Sha256", valid_602488
  var valid_602489 = header.getOrDefault("X-Amz-Date")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-Date", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-Credential")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-Credential", valid_602490
  var valid_602491 = header.getOrDefault("X-Amz-Security-Token")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Security-Token", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-Algorithm")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-Algorithm", valid_602492
  var valid_602493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-SignedHeaders", valid_602493
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_602494 = formData.getOrDefault("Deployed")
  valid_602494 = validateParameter(valid_602494, JBool, required = false, default = nil)
  if valid_602494 != nil:
    section.add "Deployed", valid_602494
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602495 = formData.getOrDefault("DomainName")
  valid_602495 = validateParameter(valid_602495, JString, required = true,
                                 default = nil)
  if valid_602495 != nil:
    section.add "DomainName", valid_602495
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602496: Call_PostDescribeDomainEndpointOptions_602482;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602496.validator(path, query, header, formData, body)
  let scheme = call_602496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602496.url(scheme.get, call_602496.host, call_602496.base,
                         call_602496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602496, url, valid)

proc call*(call_602497: Call_PostDescribeDomainEndpointOptions_602482;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeDomainEndpointOptions";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeDomainEndpointOptions
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602498 = newJObject()
  var formData_602499 = newJObject()
  add(formData_602499, "Deployed", newJBool(Deployed))
  add(formData_602499, "DomainName", newJString(DomainName))
  add(query_602498, "Action", newJString(Action))
  add(query_602498, "Version", newJString(Version))
  result = call_602497.call(nil, query_602498, nil, formData_602499, nil)

var postDescribeDomainEndpointOptions* = Call_PostDescribeDomainEndpointOptions_602482(
    name: "postDescribeDomainEndpointOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDomainEndpointOptions",
    validator: validate_PostDescribeDomainEndpointOptions_602483, base: "/",
    url: url_PostDescribeDomainEndpointOptions_602484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomainEndpointOptions_602465 = ref object of OpenApiRestCall_601389
proc url_GetDescribeDomainEndpointOptions_602467(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDomainEndpointOptions_602466(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602468 = query.getOrDefault("DomainName")
  valid_602468 = validateParameter(valid_602468, JString, required = true,
                                 default = nil)
  if valid_602468 != nil:
    section.add "DomainName", valid_602468
  var valid_602469 = query.getOrDefault("Deployed")
  valid_602469 = validateParameter(valid_602469, JBool, required = false, default = nil)
  if valid_602469 != nil:
    section.add "Deployed", valid_602469
  var valid_602470 = query.getOrDefault("Action")
  valid_602470 = validateParameter(valid_602470, JString, required = true, default = newJString(
      "DescribeDomainEndpointOptions"))
  if valid_602470 != nil:
    section.add "Action", valid_602470
  var valid_602471 = query.getOrDefault("Version")
  valid_602471 = validateParameter(valid_602471, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602471 != nil:
    section.add "Version", valid_602471
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602472 = header.getOrDefault("X-Amz-Signature")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-Signature", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Content-Sha256", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-Date")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Date", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Credential")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Credential", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Security-Token")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Security-Token", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Algorithm")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Algorithm", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-SignedHeaders", valid_602478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602479: Call_GetDescribeDomainEndpointOptions_602465;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602479.validator(path, query, header, formData, body)
  let scheme = call_602479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602479.url(scheme.get, call_602479.host, call_602479.base,
                         call_602479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602479, url, valid)

proc call*(call_602480: Call_GetDescribeDomainEndpointOptions_602465;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeDomainEndpointOptions";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeDomainEndpointOptions
  ## Returns the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to retrieve the latest configuration (which might be in a Processing state) or the current, active configuration. Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602481 = newJObject()
  add(query_602481, "DomainName", newJString(DomainName))
  add(query_602481, "Deployed", newJBool(Deployed))
  add(query_602481, "Action", newJString(Action))
  add(query_602481, "Version", newJString(Version))
  result = call_602480.call(nil, query_602481, nil, nil, nil)

var getDescribeDomainEndpointOptions* = Call_GetDescribeDomainEndpointOptions_602465(
    name: "getDescribeDomainEndpointOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDomainEndpointOptions",
    validator: validate_GetDescribeDomainEndpointOptions_602466, base: "/",
    url: url_GetDescribeDomainEndpointOptions_602467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_602516 = ref object of OpenApiRestCall_601389
proc url_PostDescribeDomains_602518(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDomains_602517(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602519 = query.getOrDefault("Action")
  valid_602519 = validateParameter(valid_602519, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_602519 != nil:
    section.add "Action", valid_602519
  var valid_602520 = query.getOrDefault("Version")
  valid_602520 = validateParameter(valid_602520, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602520 != nil:
    section.add "Version", valid_602520
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602521 = header.getOrDefault("X-Amz-Signature")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-Signature", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Content-Sha256", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Date")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Date", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-Credential")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Credential", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Security-Token")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Security-Token", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-Algorithm")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-Algorithm", valid_602526
  var valid_602527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "X-Amz-SignedHeaders", valid_602527
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_602528 = formData.getOrDefault("DomainNames")
  valid_602528 = validateParameter(valid_602528, JArray, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "DomainNames", valid_602528
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602529: Call_PostDescribeDomains_602516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602529.validator(path, query, header, formData, body)
  let scheme = call_602529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602529.url(scheme.get, call_602529.host, call_602529.base,
                         call_602529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602529, url, valid)

proc call*(call_602530: Call_PostDescribeDomains_602516;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602531 = newJObject()
  var formData_602532 = newJObject()
  if DomainNames != nil:
    formData_602532.add "DomainNames", DomainNames
  add(query_602531, "Action", newJString(Action))
  add(query_602531, "Version", newJString(Version))
  result = call_602530.call(nil, query_602531, nil, formData_602532, nil)

var postDescribeDomains* = Call_PostDescribeDomains_602516(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_602517, base: "/",
    url: url_PostDescribeDomains_602518, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_602500 = ref object of OpenApiRestCall_601389
proc url_GetDescribeDomains_602502(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDomains_602501(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_602503 = query.getOrDefault("DomainNames")
  valid_602503 = validateParameter(valid_602503, JArray, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "DomainNames", valid_602503
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602504 = query.getOrDefault("Action")
  valid_602504 = validateParameter(valid_602504, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_602504 != nil:
    section.add "Action", valid_602504
  var valid_602505 = query.getOrDefault("Version")
  valid_602505 = validateParameter(valid_602505, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602505 != nil:
    section.add "Version", valid_602505
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602506 = header.getOrDefault("X-Amz-Signature")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-Signature", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Content-Sha256", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Date")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Date", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Credential")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Credential", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Security-Token")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Security-Token", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Algorithm")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Algorithm", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-SignedHeaders", valid_602512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602513: Call_GetDescribeDomains_602500; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602513.validator(path, query, header, formData, body)
  let scheme = call_602513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602513.url(scheme.get, call_602513.host, call_602513.base,
                         call_602513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602513, url, valid)

proc call*(call_602514: Call_GetDescribeDomains_602500;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602515 = newJObject()
  if DomainNames != nil:
    query_602515.add "DomainNames", DomainNames
  add(query_602515, "Action", newJString(Action))
  add(query_602515, "Version", newJString(Version))
  result = call_602514.call(nil, query_602515, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_602500(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_602501, base: "/",
    url: url_GetDescribeDomains_602502, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeExpressions_602551 = ref object of OpenApiRestCall_601389
proc url_PostDescribeExpressions_602553(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeExpressions_602552(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602554 = query.getOrDefault("Action")
  valid_602554 = validateParameter(valid_602554, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_602554 != nil:
    section.add "Action", valid_602554
  var valid_602555 = query.getOrDefault("Version")
  valid_602555 = validateParameter(valid_602555, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602555 != nil:
    section.add "Version", valid_602555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602556 = header.getOrDefault("X-Amz-Signature")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Signature", valid_602556
  var valid_602557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-Content-Sha256", valid_602557
  var valid_602558 = header.getOrDefault("X-Amz-Date")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "X-Amz-Date", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-Credential")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Credential", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-Security-Token")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Security-Token", valid_602560
  var valid_602561 = header.getOrDefault("X-Amz-Algorithm")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-Algorithm", valid_602561
  var valid_602562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-SignedHeaders", valid_602562
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  section = newJObject()
  var valid_602563 = formData.getOrDefault("Deployed")
  valid_602563 = validateParameter(valid_602563, JBool, required = false, default = nil)
  if valid_602563 != nil:
    section.add "Deployed", valid_602563
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602564 = formData.getOrDefault("DomainName")
  valid_602564 = validateParameter(valid_602564, JString, required = true,
                                 default = nil)
  if valid_602564 != nil:
    section.add "DomainName", valid_602564
  var valid_602565 = formData.getOrDefault("ExpressionNames")
  valid_602565 = validateParameter(valid_602565, JArray, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "ExpressionNames", valid_602565
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602566: Call_PostDescribeExpressions_602551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602566.validator(path, query, header, formData, body)
  let scheme = call_602566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602566.url(scheme.get, call_602566.host, call_602566.base,
                         call_602566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602566, url, valid)

proc call*(call_602567: Call_PostDescribeExpressions_602551; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeExpressions";
          ExpressionNames: JsonNode = nil; Version: string = "2013-01-01"): Recallable =
  ## postDescribeExpressions
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  ##   Version: string (required)
  var query_602568 = newJObject()
  var formData_602569 = newJObject()
  add(formData_602569, "Deployed", newJBool(Deployed))
  add(formData_602569, "DomainName", newJString(DomainName))
  add(query_602568, "Action", newJString(Action))
  if ExpressionNames != nil:
    formData_602569.add "ExpressionNames", ExpressionNames
  add(query_602568, "Version", newJString(Version))
  result = call_602567.call(nil, query_602568, nil, formData_602569, nil)

var postDescribeExpressions* = Call_PostDescribeExpressions_602551(
    name: "postDescribeExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_PostDescribeExpressions_602552, base: "/",
    url: url_PostDescribeExpressions_602553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeExpressions_602533 = ref object of OpenApiRestCall_601389
proc url_GetDescribeExpressions_602535(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeExpressions_602534(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_602536 = query.getOrDefault("ExpressionNames")
  valid_602536 = validateParameter(valid_602536, JArray, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "ExpressionNames", valid_602536
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602537 = query.getOrDefault("DomainName")
  valid_602537 = validateParameter(valid_602537, JString, required = true,
                                 default = nil)
  if valid_602537 != nil:
    section.add "DomainName", valid_602537
  var valid_602538 = query.getOrDefault("Deployed")
  valid_602538 = validateParameter(valid_602538, JBool, required = false, default = nil)
  if valid_602538 != nil:
    section.add "Deployed", valid_602538
  var valid_602539 = query.getOrDefault("Action")
  valid_602539 = validateParameter(valid_602539, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_602539 != nil:
    section.add "Action", valid_602539
  var valid_602540 = query.getOrDefault("Version")
  valid_602540 = validateParameter(valid_602540, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602540 != nil:
    section.add "Version", valid_602540
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602541 = header.getOrDefault("X-Amz-Signature")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Signature", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Content-Sha256", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-Date")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Date", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Credential")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Credential", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Security-Token")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Security-Token", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-Algorithm")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-Algorithm", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-SignedHeaders", valid_602547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602548: Call_GetDescribeExpressions_602533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602548.validator(path, query, header, formData, body)
  let scheme = call_602548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602548.url(scheme.get, call_602548.host, call_602548.base,
                         call_602548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602548, url, valid)

proc call*(call_602549: Call_GetDescribeExpressions_602533; DomainName: string;
          ExpressionNames: JsonNode = nil; Deployed: bool = false;
          Action: string = "DescribeExpressions"; Version: string = "2013-01-01"): Recallable =
  ## getDescribeExpressions
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602550 = newJObject()
  if ExpressionNames != nil:
    query_602550.add "ExpressionNames", ExpressionNames
  add(query_602550, "DomainName", newJString(DomainName))
  add(query_602550, "Deployed", newJBool(Deployed))
  add(query_602550, "Action", newJString(Action))
  add(query_602550, "Version", newJString(Version))
  result = call_602549.call(nil, query_602550, nil, nil, nil)

var getDescribeExpressions* = Call_GetDescribeExpressions_602533(
    name: "getDescribeExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_GetDescribeExpressions_602534, base: "/",
    url: url_GetDescribeExpressions_602535, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_602588 = ref object of OpenApiRestCall_601389
proc url_PostDescribeIndexFields_602590(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeIndexFields_602589(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602591 = query.getOrDefault("Action")
  valid_602591 = validateParameter(valid_602591, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_602591 != nil:
    section.add "Action", valid_602591
  var valid_602592 = query.getOrDefault("Version")
  valid_602592 = validateParameter(valid_602592, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602592 != nil:
    section.add "Version", valid_602592
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602593 = header.getOrDefault("X-Amz-Signature")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-Signature", valid_602593
  var valid_602594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "X-Amz-Content-Sha256", valid_602594
  var valid_602595 = header.getOrDefault("X-Amz-Date")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Date", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-Credential")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Credential", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-Security-Token")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Security-Token", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Algorithm")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Algorithm", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-SignedHeaders", valid_602599
  result.add "header", section
  ## parameters in `formData` object:
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_602600 = formData.getOrDefault("FieldNames")
  valid_602600 = validateParameter(valid_602600, JArray, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "FieldNames", valid_602600
  var valid_602601 = formData.getOrDefault("Deployed")
  valid_602601 = validateParameter(valid_602601, JBool, required = false, default = nil)
  if valid_602601 != nil:
    section.add "Deployed", valid_602601
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602602 = formData.getOrDefault("DomainName")
  valid_602602 = validateParameter(valid_602602, JString, required = true,
                                 default = nil)
  if valid_602602 != nil:
    section.add "DomainName", valid_602602
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602603: Call_PostDescribeIndexFields_602588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602603.validator(path, query, header, formData, body)
  let scheme = call_602603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602603.url(scheme.get, call_602603.host, call_602603.base,
                         call_602603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602603, url, valid)

proc call*(call_602604: Call_PostDescribeIndexFields_602588; DomainName: string;
          FieldNames: JsonNode = nil; Deployed: bool = false;
          Action: string = "DescribeIndexFields"; Version: string = "2013-01-01"): Recallable =
  ## postDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602605 = newJObject()
  var formData_602606 = newJObject()
  if FieldNames != nil:
    formData_602606.add "FieldNames", FieldNames
  add(formData_602606, "Deployed", newJBool(Deployed))
  add(formData_602606, "DomainName", newJString(DomainName))
  add(query_602605, "Action", newJString(Action))
  add(query_602605, "Version", newJString(Version))
  result = call_602604.call(nil, query_602605, nil, formData_602606, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_602588(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_602589, base: "/",
    url: url_PostDescribeIndexFields_602590, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_602570 = ref object of OpenApiRestCall_601389
proc url_GetDescribeIndexFields_602572(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeIndexFields_602571(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602573 = query.getOrDefault("DomainName")
  valid_602573 = validateParameter(valid_602573, JString, required = true,
                                 default = nil)
  if valid_602573 != nil:
    section.add "DomainName", valid_602573
  var valid_602574 = query.getOrDefault("Deployed")
  valid_602574 = validateParameter(valid_602574, JBool, required = false, default = nil)
  if valid_602574 != nil:
    section.add "Deployed", valid_602574
  var valid_602575 = query.getOrDefault("Action")
  valid_602575 = validateParameter(valid_602575, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_602575 != nil:
    section.add "Action", valid_602575
  var valid_602576 = query.getOrDefault("Version")
  valid_602576 = validateParameter(valid_602576, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602576 != nil:
    section.add "Version", valid_602576
  var valid_602577 = query.getOrDefault("FieldNames")
  valid_602577 = validateParameter(valid_602577, JArray, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "FieldNames", valid_602577
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602578 = header.getOrDefault("X-Amz-Signature")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Signature", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Content-Sha256", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Date")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Date", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-Credential")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Credential", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-Security-Token")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Security-Token", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-Algorithm")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-Algorithm", valid_602583
  var valid_602584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-SignedHeaders", valid_602584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602585: Call_GetDescribeIndexFields_602570; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602585.validator(path, query, header, formData, body)
  let scheme = call_602585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602585.url(scheme.get, call_602585.host, call_602585.base,
                         call_602585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602585, url, valid)

proc call*(call_602586: Call_GetDescribeIndexFields_602570; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeIndexFields";
          Version: string = "2013-01-01"; FieldNames: JsonNode = nil): Recallable =
  ## getDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  var query_602587 = newJObject()
  add(query_602587, "DomainName", newJString(DomainName))
  add(query_602587, "Deployed", newJBool(Deployed))
  add(query_602587, "Action", newJString(Action))
  add(query_602587, "Version", newJString(Version))
  if FieldNames != nil:
    query_602587.add "FieldNames", FieldNames
  result = call_602586.call(nil, query_602587, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_602570(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_602571, base: "/",
    url: url_GetDescribeIndexFields_602572, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeScalingParameters_602623 = ref object of OpenApiRestCall_601389
proc url_PostDescribeScalingParameters_602625(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeScalingParameters_602624(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602626 = query.getOrDefault("Action")
  valid_602626 = validateParameter(valid_602626, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_602626 != nil:
    section.add "Action", valid_602626
  var valid_602627 = query.getOrDefault("Version")
  valid_602627 = validateParameter(valid_602627, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602627 != nil:
    section.add "Version", valid_602627
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602628 = header.getOrDefault("X-Amz-Signature")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Signature", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-Content-Sha256", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-Date")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Date", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-Credential")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-Credential", valid_602631
  var valid_602632 = header.getOrDefault("X-Amz-Security-Token")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "X-Amz-Security-Token", valid_602632
  var valid_602633 = header.getOrDefault("X-Amz-Algorithm")
  valid_602633 = validateParameter(valid_602633, JString, required = false,
                                 default = nil)
  if valid_602633 != nil:
    section.add "X-Amz-Algorithm", valid_602633
  var valid_602634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602634 = validateParameter(valid_602634, JString, required = false,
                                 default = nil)
  if valid_602634 != nil:
    section.add "X-Amz-SignedHeaders", valid_602634
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602635 = formData.getOrDefault("DomainName")
  valid_602635 = validateParameter(valid_602635, JString, required = true,
                                 default = nil)
  if valid_602635 != nil:
    section.add "DomainName", valid_602635
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602636: Call_PostDescribeScalingParameters_602623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602636.validator(path, query, header, formData, body)
  let scheme = call_602636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602636.url(scheme.get, call_602636.host, call_602636.base,
                         call_602636.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602636, url, valid)

proc call*(call_602637: Call_PostDescribeScalingParameters_602623;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602638 = newJObject()
  var formData_602639 = newJObject()
  add(formData_602639, "DomainName", newJString(DomainName))
  add(query_602638, "Action", newJString(Action))
  add(query_602638, "Version", newJString(Version))
  result = call_602637.call(nil, query_602638, nil, formData_602639, nil)

var postDescribeScalingParameters* = Call_PostDescribeScalingParameters_602623(
    name: "postDescribeScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_PostDescribeScalingParameters_602624, base: "/",
    url: url_PostDescribeScalingParameters_602625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeScalingParameters_602607 = ref object of OpenApiRestCall_601389
proc url_GetDescribeScalingParameters_602609(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeScalingParameters_602608(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602610 = query.getOrDefault("DomainName")
  valid_602610 = validateParameter(valid_602610, JString, required = true,
                                 default = nil)
  if valid_602610 != nil:
    section.add "DomainName", valid_602610
  var valid_602611 = query.getOrDefault("Action")
  valid_602611 = validateParameter(valid_602611, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_602611 != nil:
    section.add "Action", valid_602611
  var valid_602612 = query.getOrDefault("Version")
  valid_602612 = validateParameter(valid_602612, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602612 != nil:
    section.add "Version", valid_602612
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602613 = header.getOrDefault("X-Amz-Signature")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Signature", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-Content-Sha256", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-Date")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-Date", valid_602615
  var valid_602616 = header.getOrDefault("X-Amz-Credential")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "X-Amz-Credential", valid_602616
  var valid_602617 = header.getOrDefault("X-Amz-Security-Token")
  valid_602617 = validateParameter(valid_602617, JString, required = false,
                                 default = nil)
  if valid_602617 != nil:
    section.add "X-Amz-Security-Token", valid_602617
  var valid_602618 = header.getOrDefault("X-Amz-Algorithm")
  valid_602618 = validateParameter(valid_602618, JString, required = false,
                                 default = nil)
  if valid_602618 != nil:
    section.add "X-Amz-Algorithm", valid_602618
  var valid_602619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "X-Amz-SignedHeaders", valid_602619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602620: Call_GetDescribeScalingParameters_602607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602620.validator(path, query, header, formData, body)
  let scheme = call_602620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602620.url(scheme.get, call_602620.host, call_602620.base,
                         call_602620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602620, url, valid)

proc call*(call_602621: Call_GetDescribeScalingParameters_602607;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602622 = newJObject()
  add(query_602622, "DomainName", newJString(DomainName))
  add(query_602622, "Action", newJString(Action))
  add(query_602622, "Version", newJString(Version))
  result = call_602621.call(nil, query_602622, nil, nil, nil)

var getDescribeScalingParameters* = Call_GetDescribeScalingParameters_602607(
    name: "getDescribeScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_GetDescribeScalingParameters_602608, base: "/",
    url: url_GetDescribeScalingParameters_602609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_602657 = ref object of OpenApiRestCall_601389
proc url_PostDescribeServiceAccessPolicies_602659(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeServiceAccessPolicies_602658(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602660 = query.getOrDefault("Action")
  valid_602660 = validateParameter(valid_602660, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_602660 != nil:
    section.add "Action", valid_602660
  var valid_602661 = query.getOrDefault("Version")
  valid_602661 = validateParameter(valid_602661, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602661 != nil:
    section.add "Version", valid_602661
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602662 = header.getOrDefault("X-Amz-Signature")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-Signature", valid_602662
  var valid_602663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602663 = validateParameter(valid_602663, JString, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "X-Amz-Content-Sha256", valid_602663
  var valid_602664 = header.getOrDefault("X-Amz-Date")
  valid_602664 = validateParameter(valid_602664, JString, required = false,
                                 default = nil)
  if valid_602664 != nil:
    section.add "X-Amz-Date", valid_602664
  var valid_602665 = header.getOrDefault("X-Amz-Credential")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "X-Amz-Credential", valid_602665
  var valid_602666 = header.getOrDefault("X-Amz-Security-Token")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "X-Amz-Security-Token", valid_602666
  var valid_602667 = header.getOrDefault("X-Amz-Algorithm")
  valid_602667 = validateParameter(valid_602667, JString, required = false,
                                 default = nil)
  if valid_602667 != nil:
    section.add "X-Amz-Algorithm", valid_602667
  var valid_602668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602668 = validateParameter(valid_602668, JString, required = false,
                                 default = nil)
  if valid_602668 != nil:
    section.add "X-Amz-SignedHeaders", valid_602668
  result.add "header", section
  ## parameters in `formData` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_602669 = formData.getOrDefault("Deployed")
  valid_602669 = validateParameter(valid_602669, JBool, required = false, default = nil)
  if valid_602669 != nil:
    section.add "Deployed", valid_602669
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602670 = formData.getOrDefault("DomainName")
  valid_602670 = validateParameter(valid_602670, JString, required = true,
                                 default = nil)
  if valid_602670 != nil:
    section.add "DomainName", valid_602670
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602671: Call_PostDescribeServiceAccessPolicies_602657;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602671.validator(path, query, header, formData, body)
  let scheme = call_602671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602671.url(scheme.get, call_602671.host, call_602671.base,
                         call_602671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602671, url, valid)

proc call*(call_602672: Call_PostDescribeServiceAccessPolicies_602657;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602673 = newJObject()
  var formData_602674 = newJObject()
  add(formData_602674, "Deployed", newJBool(Deployed))
  add(formData_602674, "DomainName", newJString(DomainName))
  add(query_602673, "Action", newJString(Action))
  add(query_602673, "Version", newJString(Version))
  result = call_602672.call(nil, query_602673, nil, formData_602674, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_602657(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_602658, base: "/",
    url: url_PostDescribeServiceAccessPolicies_602659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_602640 = ref object of OpenApiRestCall_601389
proc url_GetDescribeServiceAccessPolicies_602642(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeServiceAccessPolicies_602641(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602643 = query.getOrDefault("DomainName")
  valid_602643 = validateParameter(valid_602643, JString, required = true,
                                 default = nil)
  if valid_602643 != nil:
    section.add "DomainName", valid_602643
  var valid_602644 = query.getOrDefault("Deployed")
  valid_602644 = validateParameter(valid_602644, JBool, required = false, default = nil)
  if valid_602644 != nil:
    section.add "Deployed", valid_602644
  var valid_602645 = query.getOrDefault("Action")
  valid_602645 = validateParameter(valid_602645, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_602645 != nil:
    section.add "Action", valid_602645
  var valid_602646 = query.getOrDefault("Version")
  valid_602646 = validateParameter(valid_602646, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602646 != nil:
    section.add "Version", valid_602646
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602647 = header.getOrDefault("X-Amz-Signature")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-Signature", valid_602647
  var valid_602648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602648 = validateParameter(valid_602648, JString, required = false,
                                 default = nil)
  if valid_602648 != nil:
    section.add "X-Amz-Content-Sha256", valid_602648
  var valid_602649 = header.getOrDefault("X-Amz-Date")
  valid_602649 = validateParameter(valid_602649, JString, required = false,
                                 default = nil)
  if valid_602649 != nil:
    section.add "X-Amz-Date", valid_602649
  var valid_602650 = header.getOrDefault("X-Amz-Credential")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "X-Amz-Credential", valid_602650
  var valid_602651 = header.getOrDefault("X-Amz-Security-Token")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "X-Amz-Security-Token", valid_602651
  var valid_602652 = header.getOrDefault("X-Amz-Algorithm")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "X-Amz-Algorithm", valid_602652
  var valid_602653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "X-Amz-SignedHeaders", valid_602653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602654: Call_GetDescribeServiceAccessPolicies_602640;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602654.validator(path, query, header, formData, body)
  let scheme = call_602654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602654.url(scheme.get, call_602654.host, call_602654.base,
                         call_602654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602654, url, valid)

proc call*(call_602655: Call_GetDescribeServiceAccessPolicies_602640;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602656 = newJObject()
  add(query_602656, "DomainName", newJString(DomainName))
  add(query_602656, "Deployed", newJBool(Deployed))
  add(query_602656, "Action", newJString(Action))
  add(query_602656, "Version", newJString(Version))
  result = call_602655.call(nil, query_602656, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_602640(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_602641, base: "/",
    url: url_GetDescribeServiceAccessPolicies_602642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSuggesters_602693 = ref object of OpenApiRestCall_601389
proc url_PostDescribeSuggesters_602695(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeSuggesters_602694(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602696 = query.getOrDefault("Action")
  valid_602696 = validateParameter(valid_602696, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_602696 != nil:
    section.add "Action", valid_602696
  var valid_602697 = query.getOrDefault("Version")
  valid_602697 = validateParameter(valid_602697, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602697 != nil:
    section.add "Version", valid_602697
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602698 = header.getOrDefault("X-Amz-Signature")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Signature", valid_602698
  var valid_602699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "X-Amz-Content-Sha256", valid_602699
  var valid_602700 = header.getOrDefault("X-Amz-Date")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-Date", valid_602700
  var valid_602701 = header.getOrDefault("X-Amz-Credential")
  valid_602701 = validateParameter(valid_602701, JString, required = false,
                                 default = nil)
  if valid_602701 != nil:
    section.add "X-Amz-Credential", valid_602701
  var valid_602702 = header.getOrDefault("X-Amz-Security-Token")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "X-Amz-Security-Token", valid_602702
  var valid_602703 = header.getOrDefault("X-Amz-Algorithm")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "X-Amz-Algorithm", valid_602703
  var valid_602704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602704 = validateParameter(valid_602704, JString, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "X-Amz-SignedHeaders", valid_602704
  result.add "header", section
  ## parameters in `formData` object:
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_602705 = formData.getOrDefault("SuggesterNames")
  valid_602705 = validateParameter(valid_602705, JArray, required = false,
                                 default = nil)
  if valid_602705 != nil:
    section.add "SuggesterNames", valid_602705
  var valid_602706 = formData.getOrDefault("Deployed")
  valid_602706 = validateParameter(valid_602706, JBool, required = false, default = nil)
  if valid_602706 != nil:
    section.add "Deployed", valid_602706
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602707 = formData.getOrDefault("DomainName")
  valid_602707 = validateParameter(valid_602707, JString, required = true,
                                 default = nil)
  if valid_602707 != nil:
    section.add "DomainName", valid_602707
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602708: Call_PostDescribeSuggesters_602693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602708.validator(path, query, header, formData, body)
  let scheme = call_602708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602708.url(scheme.get, call_602708.host, call_602708.base,
                         call_602708.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602708, url, valid)

proc call*(call_602709: Call_PostDescribeSuggesters_602693; DomainName: string;
          SuggesterNames: JsonNode = nil; Deployed: bool = false;
          Action: string = "DescribeSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## postDescribeSuggesters
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602710 = newJObject()
  var formData_602711 = newJObject()
  if SuggesterNames != nil:
    formData_602711.add "SuggesterNames", SuggesterNames
  add(formData_602711, "Deployed", newJBool(Deployed))
  add(formData_602711, "DomainName", newJString(DomainName))
  add(query_602710, "Action", newJString(Action))
  add(query_602710, "Version", newJString(Version))
  result = call_602709.call(nil, query_602710, nil, formData_602711, nil)

var postDescribeSuggesters* = Call_PostDescribeSuggesters_602693(
    name: "postDescribeSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_PostDescribeSuggesters_602694, base: "/",
    url: url_PostDescribeSuggesters_602695, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSuggesters_602675 = ref object of OpenApiRestCall_601389
proc url_GetDescribeSuggesters_602677(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeSuggesters_602676(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602678 = query.getOrDefault("DomainName")
  valid_602678 = validateParameter(valid_602678, JString, required = true,
                                 default = nil)
  if valid_602678 != nil:
    section.add "DomainName", valid_602678
  var valid_602679 = query.getOrDefault("Deployed")
  valid_602679 = validateParameter(valid_602679, JBool, required = false, default = nil)
  if valid_602679 != nil:
    section.add "Deployed", valid_602679
  var valid_602680 = query.getOrDefault("Action")
  valid_602680 = validateParameter(valid_602680, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_602680 != nil:
    section.add "Action", valid_602680
  var valid_602681 = query.getOrDefault("Version")
  valid_602681 = validateParameter(valid_602681, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602681 != nil:
    section.add "Version", valid_602681
  var valid_602682 = query.getOrDefault("SuggesterNames")
  valid_602682 = validateParameter(valid_602682, JArray, required = false,
                                 default = nil)
  if valid_602682 != nil:
    section.add "SuggesterNames", valid_602682
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602683 = header.getOrDefault("X-Amz-Signature")
  valid_602683 = validateParameter(valid_602683, JString, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "X-Amz-Signature", valid_602683
  var valid_602684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602684 = validateParameter(valid_602684, JString, required = false,
                                 default = nil)
  if valid_602684 != nil:
    section.add "X-Amz-Content-Sha256", valid_602684
  var valid_602685 = header.getOrDefault("X-Amz-Date")
  valid_602685 = validateParameter(valid_602685, JString, required = false,
                                 default = nil)
  if valid_602685 != nil:
    section.add "X-Amz-Date", valid_602685
  var valid_602686 = header.getOrDefault("X-Amz-Credential")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "X-Amz-Credential", valid_602686
  var valid_602687 = header.getOrDefault("X-Amz-Security-Token")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-Security-Token", valid_602687
  var valid_602688 = header.getOrDefault("X-Amz-Algorithm")
  valid_602688 = validateParameter(valid_602688, JString, required = false,
                                 default = nil)
  if valid_602688 != nil:
    section.add "X-Amz-Algorithm", valid_602688
  var valid_602689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602689 = validateParameter(valid_602689, JString, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "X-Amz-SignedHeaders", valid_602689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602690: Call_GetDescribeSuggesters_602675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602690.validator(path, query, header, formData, body)
  let scheme = call_602690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602690.url(scheme.get, call_602690.host, call_602690.base,
                         call_602690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602690, url, valid)

proc call*(call_602691: Call_GetDescribeSuggesters_602675; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeSuggesters";
          Version: string = "2013-01-01"; SuggesterNames: JsonNode = nil): Recallable =
  ## getDescribeSuggesters
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  var query_602692 = newJObject()
  add(query_602692, "DomainName", newJString(DomainName))
  add(query_602692, "Deployed", newJBool(Deployed))
  add(query_602692, "Action", newJString(Action))
  add(query_602692, "Version", newJString(Version))
  if SuggesterNames != nil:
    query_602692.add "SuggesterNames", SuggesterNames
  result = call_602691.call(nil, query_602692, nil, nil, nil)

var getDescribeSuggesters* = Call_GetDescribeSuggesters_602675(
    name: "getDescribeSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_GetDescribeSuggesters_602676, base: "/",
    url: url_GetDescribeSuggesters_602677, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_602728 = ref object of OpenApiRestCall_601389
proc url_PostIndexDocuments_602730(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostIndexDocuments_602729(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602731 = query.getOrDefault("Action")
  valid_602731 = validateParameter(valid_602731, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_602731 != nil:
    section.add "Action", valid_602731
  var valid_602732 = query.getOrDefault("Version")
  valid_602732 = validateParameter(valid_602732, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602732 != nil:
    section.add "Version", valid_602732
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602733 = header.getOrDefault("X-Amz-Signature")
  valid_602733 = validateParameter(valid_602733, JString, required = false,
                                 default = nil)
  if valid_602733 != nil:
    section.add "X-Amz-Signature", valid_602733
  var valid_602734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602734 = validateParameter(valid_602734, JString, required = false,
                                 default = nil)
  if valid_602734 != nil:
    section.add "X-Amz-Content-Sha256", valid_602734
  var valid_602735 = header.getOrDefault("X-Amz-Date")
  valid_602735 = validateParameter(valid_602735, JString, required = false,
                                 default = nil)
  if valid_602735 != nil:
    section.add "X-Amz-Date", valid_602735
  var valid_602736 = header.getOrDefault("X-Amz-Credential")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "X-Amz-Credential", valid_602736
  var valid_602737 = header.getOrDefault("X-Amz-Security-Token")
  valid_602737 = validateParameter(valid_602737, JString, required = false,
                                 default = nil)
  if valid_602737 != nil:
    section.add "X-Amz-Security-Token", valid_602737
  var valid_602738 = header.getOrDefault("X-Amz-Algorithm")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "X-Amz-Algorithm", valid_602738
  var valid_602739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602739 = validateParameter(valid_602739, JString, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "X-Amz-SignedHeaders", valid_602739
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602740 = formData.getOrDefault("DomainName")
  valid_602740 = validateParameter(valid_602740, JString, required = true,
                                 default = nil)
  if valid_602740 != nil:
    section.add "DomainName", valid_602740
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602741: Call_PostIndexDocuments_602728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_602741.validator(path, query, header, formData, body)
  let scheme = call_602741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602741.url(scheme.get, call_602741.host, call_602741.base,
                         call_602741.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602741, url, valid)

proc call*(call_602742: Call_PostIndexDocuments_602728; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602743 = newJObject()
  var formData_602744 = newJObject()
  add(formData_602744, "DomainName", newJString(DomainName))
  add(query_602743, "Action", newJString(Action))
  add(query_602743, "Version", newJString(Version))
  result = call_602742.call(nil, query_602743, nil, formData_602744, nil)

var postIndexDocuments* = Call_PostIndexDocuments_602728(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_602729, base: "/",
    url: url_PostIndexDocuments_602730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_602712 = ref object of OpenApiRestCall_601389
proc url_GetIndexDocuments_602714(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIndexDocuments_602713(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602715 = query.getOrDefault("DomainName")
  valid_602715 = validateParameter(valid_602715, JString, required = true,
                                 default = nil)
  if valid_602715 != nil:
    section.add "DomainName", valid_602715
  var valid_602716 = query.getOrDefault("Action")
  valid_602716 = validateParameter(valid_602716, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_602716 != nil:
    section.add "Action", valid_602716
  var valid_602717 = query.getOrDefault("Version")
  valid_602717 = validateParameter(valid_602717, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602717 != nil:
    section.add "Version", valid_602717
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602718 = header.getOrDefault("X-Amz-Signature")
  valid_602718 = validateParameter(valid_602718, JString, required = false,
                                 default = nil)
  if valid_602718 != nil:
    section.add "X-Amz-Signature", valid_602718
  var valid_602719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602719 = validateParameter(valid_602719, JString, required = false,
                                 default = nil)
  if valid_602719 != nil:
    section.add "X-Amz-Content-Sha256", valid_602719
  var valid_602720 = header.getOrDefault("X-Amz-Date")
  valid_602720 = validateParameter(valid_602720, JString, required = false,
                                 default = nil)
  if valid_602720 != nil:
    section.add "X-Amz-Date", valid_602720
  var valid_602721 = header.getOrDefault("X-Amz-Credential")
  valid_602721 = validateParameter(valid_602721, JString, required = false,
                                 default = nil)
  if valid_602721 != nil:
    section.add "X-Amz-Credential", valid_602721
  var valid_602722 = header.getOrDefault("X-Amz-Security-Token")
  valid_602722 = validateParameter(valid_602722, JString, required = false,
                                 default = nil)
  if valid_602722 != nil:
    section.add "X-Amz-Security-Token", valid_602722
  var valid_602723 = header.getOrDefault("X-Amz-Algorithm")
  valid_602723 = validateParameter(valid_602723, JString, required = false,
                                 default = nil)
  if valid_602723 != nil:
    section.add "X-Amz-Algorithm", valid_602723
  var valid_602724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602724 = validateParameter(valid_602724, JString, required = false,
                                 default = nil)
  if valid_602724 != nil:
    section.add "X-Amz-SignedHeaders", valid_602724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602725: Call_GetIndexDocuments_602712; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_602725.validator(path, query, header, formData, body)
  let scheme = call_602725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602725.url(scheme.get, call_602725.host, call_602725.base,
                         call_602725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602725, url, valid)

proc call*(call_602726: Call_GetIndexDocuments_602712; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602727 = newJObject()
  add(query_602727, "DomainName", newJString(DomainName))
  add(query_602727, "Action", newJString(Action))
  add(query_602727, "Version", newJString(Version))
  result = call_602726.call(nil, query_602727, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_602712(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_602713,
    base: "/", url: url_GetIndexDocuments_602714,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomainNames_602760 = ref object of OpenApiRestCall_601389
proc url_PostListDomainNames_602762(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListDomainNames_602761(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all search domains owned by an account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602763 = query.getOrDefault("Action")
  valid_602763 = validateParameter(valid_602763, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_602763 != nil:
    section.add "Action", valid_602763
  var valid_602764 = query.getOrDefault("Version")
  valid_602764 = validateParameter(valid_602764, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602764 != nil:
    section.add "Version", valid_602764
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602765 = header.getOrDefault("X-Amz-Signature")
  valid_602765 = validateParameter(valid_602765, JString, required = false,
                                 default = nil)
  if valid_602765 != nil:
    section.add "X-Amz-Signature", valid_602765
  var valid_602766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602766 = validateParameter(valid_602766, JString, required = false,
                                 default = nil)
  if valid_602766 != nil:
    section.add "X-Amz-Content-Sha256", valid_602766
  var valid_602767 = header.getOrDefault("X-Amz-Date")
  valid_602767 = validateParameter(valid_602767, JString, required = false,
                                 default = nil)
  if valid_602767 != nil:
    section.add "X-Amz-Date", valid_602767
  var valid_602768 = header.getOrDefault("X-Amz-Credential")
  valid_602768 = validateParameter(valid_602768, JString, required = false,
                                 default = nil)
  if valid_602768 != nil:
    section.add "X-Amz-Credential", valid_602768
  var valid_602769 = header.getOrDefault("X-Amz-Security-Token")
  valid_602769 = validateParameter(valid_602769, JString, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "X-Amz-Security-Token", valid_602769
  var valid_602770 = header.getOrDefault("X-Amz-Algorithm")
  valid_602770 = validateParameter(valid_602770, JString, required = false,
                                 default = nil)
  if valid_602770 != nil:
    section.add "X-Amz-Algorithm", valid_602770
  var valid_602771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "X-Amz-SignedHeaders", valid_602771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602772: Call_PostListDomainNames_602760; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_602772.validator(path, query, header, formData, body)
  let scheme = call_602772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602772.url(scheme.get, call_602772.host, call_602772.base,
                         call_602772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602772, url, valid)

proc call*(call_602773: Call_PostListDomainNames_602760;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## postListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602774 = newJObject()
  add(query_602774, "Action", newJString(Action))
  add(query_602774, "Version", newJString(Version))
  result = call_602773.call(nil, query_602774, nil, nil, nil)

var postListDomainNames* = Call_PostListDomainNames_602760(
    name: "postListDomainNames", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_PostListDomainNames_602761, base: "/",
    url: url_PostListDomainNames_602762, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomainNames_602745 = ref object of OpenApiRestCall_601389
proc url_GetListDomainNames_602747(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListDomainNames_602746(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Lists all search domains owned by an account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602748 = query.getOrDefault("Action")
  valid_602748 = validateParameter(valid_602748, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_602748 != nil:
    section.add "Action", valid_602748
  var valid_602749 = query.getOrDefault("Version")
  valid_602749 = validateParameter(valid_602749, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602749 != nil:
    section.add "Version", valid_602749
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602750 = header.getOrDefault("X-Amz-Signature")
  valid_602750 = validateParameter(valid_602750, JString, required = false,
                                 default = nil)
  if valid_602750 != nil:
    section.add "X-Amz-Signature", valid_602750
  var valid_602751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602751 = validateParameter(valid_602751, JString, required = false,
                                 default = nil)
  if valid_602751 != nil:
    section.add "X-Amz-Content-Sha256", valid_602751
  var valid_602752 = header.getOrDefault("X-Amz-Date")
  valid_602752 = validateParameter(valid_602752, JString, required = false,
                                 default = nil)
  if valid_602752 != nil:
    section.add "X-Amz-Date", valid_602752
  var valid_602753 = header.getOrDefault("X-Amz-Credential")
  valid_602753 = validateParameter(valid_602753, JString, required = false,
                                 default = nil)
  if valid_602753 != nil:
    section.add "X-Amz-Credential", valid_602753
  var valid_602754 = header.getOrDefault("X-Amz-Security-Token")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-Security-Token", valid_602754
  var valid_602755 = header.getOrDefault("X-Amz-Algorithm")
  valid_602755 = validateParameter(valid_602755, JString, required = false,
                                 default = nil)
  if valid_602755 != nil:
    section.add "X-Amz-Algorithm", valid_602755
  var valid_602756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "X-Amz-SignedHeaders", valid_602756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602757: Call_GetListDomainNames_602745; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_602757.validator(path, query, header, formData, body)
  let scheme = call_602757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602757.url(scheme.get, call_602757.host, call_602757.base,
                         call_602757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602757, url, valid)

proc call*(call_602758: Call_GetListDomainNames_602745;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## getListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602759 = newJObject()
  add(query_602759, "Action", newJString(Action))
  add(query_602759, "Version", newJString(Version))
  result = call_602758.call(nil, query_602759, nil, nil, nil)

var getListDomainNames* = Call_GetListDomainNames_602745(
    name: "getListDomainNames", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_GetListDomainNames_602746, base: "/",
    url: url_GetListDomainNames_602747, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_602792 = ref object of OpenApiRestCall_601389
proc url_PostUpdateAvailabilityOptions_602794(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateAvailabilityOptions_602793(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602795 = query.getOrDefault("Action")
  valid_602795 = validateParameter(valid_602795, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_602795 != nil:
    section.add "Action", valid_602795
  var valid_602796 = query.getOrDefault("Version")
  valid_602796 = validateParameter(valid_602796, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602796 != nil:
    section.add "Version", valid_602796
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602797 = header.getOrDefault("X-Amz-Signature")
  valid_602797 = validateParameter(valid_602797, JString, required = false,
                                 default = nil)
  if valid_602797 != nil:
    section.add "X-Amz-Signature", valid_602797
  var valid_602798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "X-Amz-Content-Sha256", valid_602798
  var valid_602799 = header.getOrDefault("X-Amz-Date")
  valid_602799 = validateParameter(valid_602799, JString, required = false,
                                 default = nil)
  if valid_602799 != nil:
    section.add "X-Amz-Date", valid_602799
  var valid_602800 = header.getOrDefault("X-Amz-Credential")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "X-Amz-Credential", valid_602800
  var valid_602801 = header.getOrDefault("X-Amz-Security-Token")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "X-Amz-Security-Token", valid_602801
  var valid_602802 = header.getOrDefault("X-Amz-Algorithm")
  valid_602802 = validateParameter(valid_602802, JString, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "X-Amz-Algorithm", valid_602802
  var valid_602803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602803 = validateParameter(valid_602803, JString, required = false,
                                 default = nil)
  if valid_602803 != nil:
    section.add "X-Amz-SignedHeaders", valid_602803
  result.add "header", section
  ## parameters in `formData` object:
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MultiAZ` field"
  var valid_602804 = formData.getOrDefault("MultiAZ")
  valid_602804 = validateParameter(valid_602804, JBool, required = true, default = nil)
  if valid_602804 != nil:
    section.add "MultiAZ", valid_602804
  var valid_602805 = formData.getOrDefault("DomainName")
  valid_602805 = validateParameter(valid_602805, JString, required = true,
                                 default = nil)
  if valid_602805 != nil:
    section.add "DomainName", valid_602805
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602806: Call_PostUpdateAvailabilityOptions_602792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602806.validator(path, query, header, formData, body)
  let scheme = call_602806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602806.url(scheme.get, call_602806.host, call_602806.base,
                         call_602806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602806, url, valid)

proc call*(call_602807: Call_PostUpdateAvailabilityOptions_602792; MultiAZ: bool;
          DomainName: string; Action: string = "UpdateAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602808 = newJObject()
  var formData_602809 = newJObject()
  add(formData_602809, "MultiAZ", newJBool(MultiAZ))
  add(formData_602809, "DomainName", newJString(DomainName))
  add(query_602808, "Action", newJString(Action))
  add(query_602808, "Version", newJString(Version))
  result = call_602807.call(nil, query_602808, nil, formData_602809, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_602792(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_602793, base: "/",
    url: url_PostUpdateAvailabilityOptions_602794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_602775 = ref object of OpenApiRestCall_601389
proc url_GetUpdateAvailabilityOptions_602777(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateAvailabilityOptions_602776(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602778 = query.getOrDefault("DomainName")
  valid_602778 = validateParameter(valid_602778, JString, required = true,
                                 default = nil)
  if valid_602778 != nil:
    section.add "DomainName", valid_602778
  var valid_602779 = query.getOrDefault("Action")
  valid_602779 = validateParameter(valid_602779, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_602779 != nil:
    section.add "Action", valid_602779
  var valid_602780 = query.getOrDefault("MultiAZ")
  valid_602780 = validateParameter(valid_602780, JBool, required = true, default = nil)
  if valid_602780 != nil:
    section.add "MultiAZ", valid_602780
  var valid_602781 = query.getOrDefault("Version")
  valid_602781 = validateParameter(valid_602781, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602781 != nil:
    section.add "Version", valid_602781
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602782 = header.getOrDefault("X-Amz-Signature")
  valid_602782 = validateParameter(valid_602782, JString, required = false,
                                 default = nil)
  if valid_602782 != nil:
    section.add "X-Amz-Signature", valid_602782
  var valid_602783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602783 = validateParameter(valid_602783, JString, required = false,
                                 default = nil)
  if valid_602783 != nil:
    section.add "X-Amz-Content-Sha256", valid_602783
  var valid_602784 = header.getOrDefault("X-Amz-Date")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "X-Amz-Date", valid_602784
  var valid_602785 = header.getOrDefault("X-Amz-Credential")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-Credential", valid_602785
  var valid_602786 = header.getOrDefault("X-Amz-Security-Token")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-Security-Token", valid_602786
  var valid_602787 = header.getOrDefault("X-Amz-Algorithm")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "X-Amz-Algorithm", valid_602787
  var valid_602788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602788 = validateParameter(valid_602788, JString, required = false,
                                 default = nil)
  if valid_602788 != nil:
    section.add "X-Amz-SignedHeaders", valid_602788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602789: Call_GetUpdateAvailabilityOptions_602775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602789.validator(path, query, header, formData, body)
  let scheme = call_602789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602789.url(scheme.get, call_602789.host, call_602789.base,
                         call_602789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602789, url, valid)

proc call*(call_602790: Call_GetUpdateAvailabilityOptions_602775;
          DomainName: string; MultiAZ: bool;
          Action: string = "UpdateAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## getUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Version: string (required)
  var query_602791 = newJObject()
  add(query_602791, "DomainName", newJString(DomainName))
  add(query_602791, "Action", newJString(Action))
  add(query_602791, "MultiAZ", newJBool(MultiAZ))
  add(query_602791, "Version", newJString(Version))
  result = call_602790.call(nil, query_602791, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_602775(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_602776, base: "/",
    url: url_GetUpdateAvailabilityOptions_602777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDomainEndpointOptions_602828 = ref object of OpenApiRestCall_601389
proc url_PostUpdateDomainEndpointOptions_602830(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateDomainEndpointOptions_602829(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602831 = query.getOrDefault("Action")
  valid_602831 = validateParameter(valid_602831, JString, required = true, default = newJString(
      "UpdateDomainEndpointOptions"))
  if valid_602831 != nil:
    section.add "Action", valid_602831
  var valid_602832 = query.getOrDefault("Version")
  valid_602832 = validateParameter(valid_602832, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602832 != nil:
    section.add "Version", valid_602832
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602833 = header.getOrDefault("X-Amz-Signature")
  valid_602833 = validateParameter(valid_602833, JString, required = false,
                                 default = nil)
  if valid_602833 != nil:
    section.add "X-Amz-Signature", valid_602833
  var valid_602834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-Content-Sha256", valid_602834
  var valid_602835 = header.getOrDefault("X-Amz-Date")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "X-Amz-Date", valid_602835
  var valid_602836 = header.getOrDefault("X-Amz-Credential")
  valid_602836 = validateParameter(valid_602836, JString, required = false,
                                 default = nil)
  if valid_602836 != nil:
    section.add "X-Amz-Credential", valid_602836
  var valid_602837 = header.getOrDefault("X-Amz-Security-Token")
  valid_602837 = validateParameter(valid_602837, JString, required = false,
                                 default = nil)
  if valid_602837 != nil:
    section.add "X-Amz-Security-Token", valid_602837
  var valid_602838 = header.getOrDefault("X-Amz-Algorithm")
  valid_602838 = validateParameter(valid_602838, JString, required = false,
                                 default = nil)
  if valid_602838 != nil:
    section.add "X-Amz-Algorithm", valid_602838
  var valid_602839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602839 = validateParameter(valid_602839, JString, required = false,
                                 default = nil)
  if valid_602839 != nil:
    section.add "X-Amz-SignedHeaders", valid_602839
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainEndpointOptions.TLSSecurityPolicy: JString
  ##                                          : The domain's endpoint options.
  ## The minimum required TLS version
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   DomainEndpointOptions.EnforceHTTPS: JString
  ##                                     : The domain's endpoint options.
  ## Whether the domain is HTTPS only enabled.
  section = newJObject()
  var valid_602840 = formData.getOrDefault("DomainEndpointOptions.TLSSecurityPolicy")
  valid_602840 = validateParameter(valid_602840, JString, required = false,
                                 default = nil)
  if valid_602840 != nil:
    section.add "DomainEndpointOptions.TLSSecurityPolicy", valid_602840
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602841 = formData.getOrDefault("DomainName")
  valid_602841 = validateParameter(valid_602841, JString, required = true,
                                 default = nil)
  if valid_602841 != nil:
    section.add "DomainName", valid_602841
  var valid_602842 = formData.getOrDefault("DomainEndpointOptions.EnforceHTTPS")
  valid_602842 = validateParameter(valid_602842, JString, required = false,
                                 default = nil)
  if valid_602842 != nil:
    section.add "DomainEndpointOptions.EnforceHTTPS", valid_602842
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602843: Call_PostUpdateDomainEndpointOptions_602828;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602843.validator(path, query, header, formData, body)
  let scheme = call_602843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602843.url(scheme.get, call_602843.host, call_602843.base,
                         call_602843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602843, url, valid)

proc call*(call_602844: Call_PostUpdateDomainEndpointOptions_602828;
          DomainName: string; DomainEndpointOptionsTLSSecurityPolicy: string = "";
          Action: string = "UpdateDomainEndpointOptions";
          DomainEndpointOptionsEnforceHTTPS: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateDomainEndpointOptions
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainEndpointOptionsTLSSecurityPolicy: string
  ##                                         : The domain's endpoint options.
  ## The minimum required TLS version
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   DomainEndpointOptionsEnforceHTTPS: string
  ##                                    : The domain's endpoint options.
  ## Whether the domain is HTTPS only enabled.
  ##   Version: string (required)
  var query_602845 = newJObject()
  var formData_602846 = newJObject()
  add(formData_602846, "DomainEndpointOptions.TLSSecurityPolicy",
      newJString(DomainEndpointOptionsTLSSecurityPolicy))
  add(formData_602846, "DomainName", newJString(DomainName))
  add(query_602845, "Action", newJString(Action))
  add(formData_602846, "DomainEndpointOptions.EnforceHTTPS",
      newJString(DomainEndpointOptionsEnforceHTTPS))
  add(query_602845, "Version", newJString(Version))
  result = call_602844.call(nil, query_602845, nil, formData_602846, nil)

var postUpdateDomainEndpointOptions* = Call_PostUpdateDomainEndpointOptions_602828(
    name: "postUpdateDomainEndpointOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateDomainEndpointOptions",
    validator: validate_PostUpdateDomainEndpointOptions_602829, base: "/",
    url: url_PostUpdateDomainEndpointOptions_602830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDomainEndpointOptions_602810 = ref object of OpenApiRestCall_601389
proc url_GetUpdateDomainEndpointOptions_602812(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateDomainEndpointOptions_602811(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainEndpointOptions.EnforceHTTPS: JString
  ##                                     : The domain's endpoint options.
  ## Whether the domain is HTTPS only enabled.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   DomainEndpointOptions.TLSSecurityPolicy: JString
  ##                                          : The domain's endpoint options.
  ## The minimum required TLS version
  ##   Version: JString (required)
  section = newJObject()
  var valid_602813 = query.getOrDefault("DomainEndpointOptions.EnforceHTTPS")
  valid_602813 = validateParameter(valid_602813, JString, required = false,
                                 default = nil)
  if valid_602813 != nil:
    section.add "DomainEndpointOptions.EnforceHTTPS", valid_602813
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602814 = query.getOrDefault("DomainName")
  valid_602814 = validateParameter(valid_602814, JString, required = true,
                                 default = nil)
  if valid_602814 != nil:
    section.add "DomainName", valid_602814
  var valid_602815 = query.getOrDefault("Action")
  valid_602815 = validateParameter(valid_602815, JString, required = true, default = newJString(
      "UpdateDomainEndpointOptions"))
  if valid_602815 != nil:
    section.add "Action", valid_602815
  var valid_602816 = query.getOrDefault("DomainEndpointOptions.TLSSecurityPolicy")
  valid_602816 = validateParameter(valid_602816, JString, required = false,
                                 default = nil)
  if valid_602816 != nil:
    section.add "DomainEndpointOptions.TLSSecurityPolicy", valid_602816
  var valid_602817 = query.getOrDefault("Version")
  valid_602817 = validateParameter(valid_602817, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602817 != nil:
    section.add "Version", valid_602817
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602818 = header.getOrDefault("X-Amz-Signature")
  valid_602818 = validateParameter(valid_602818, JString, required = false,
                                 default = nil)
  if valid_602818 != nil:
    section.add "X-Amz-Signature", valid_602818
  var valid_602819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602819 = validateParameter(valid_602819, JString, required = false,
                                 default = nil)
  if valid_602819 != nil:
    section.add "X-Amz-Content-Sha256", valid_602819
  var valid_602820 = header.getOrDefault("X-Amz-Date")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-Date", valid_602820
  var valid_602821 = header.getOrDefault("X-Amz-Credential")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "X-Amz-Credential", valid_602821
  var valid_602822 = header.getOrDefault("X-Amz-Security-Token")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "X-Amz-Security-Token", valid_602822
  var valid_602823 = header.getOrDefault("X-Amz-Algorithm")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "X-Amz-Algorithm", valid_602823
  var valid_602824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602824 = validateParameter(valid_602824, JString, required = false,
                                 default = nil)
  if valid_602824 != nil:
    section.add "X-Amz-SignedHeaders", valid_602824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602825: Call_GetUpdateDomainEndpointOptions_602810; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602825.validator(path, query, header, formData, body)
  let scheme = call_602825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602825.url(scheme.get, call_602825.host, call_602825.base,
                         call_602825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602825, url, valid)

proc call*(call_602826: Call_GetUpdateDomainEndpointOptions_602810;
          DomainName: string; DomainEndpointOptionsEnforceHTTPS: string = "";
          Action: string = "UpdateDomainEndpointOptions";
          DomainEndpointOptionsTLSSecurityPolicy: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## getUpdateDomainEndpointOptions
  ## Updates the domain's endpoint options, specifically whether all requests to the domain must arrive over HTTPS. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-domain-endpoint-options.html" target="_blank">Configuring Domain Endpoint Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainEndpointOptionsEnforceHTTPS: string
  ##                                    : The domain's endpoint options.
  ## Whether the domain is HTTPS only enabled.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   DomainEndpointOptionsTLSSecurityPolicy: string
  ##                                         : The domain's endpoint options.
  ## The minimum required TLS version
  ##   Version: string (required)
  var query_602827 = newJObject()
  add(query_602827, "DomainEndpointOptions.EnforceHTTPS",
      newJString(DomainEndpointOptionsEnforceHTTPS))
  add(query_602827, "DomainName", newJString(DomainName))
  add(query_602827, "Action", newJString(Action))
  add(query_602827, "DomainEndpointOptions.TLSSecurityPolicy",
      newJString(DomainEndpointOptionsTLSSecurityPolicy))
  add(query_602827, "Version", newJString(Version))
  result = call_602826.call(nil, query_602827, nil, nil, nil)

var getUpdateDomainEndpointOptions* = Call_GetUpdateDomainEndpointOptions_602810(
    name: "getUpdateDomainEndpointOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateDomainEndpointOptions",
    validator: validate_GetUpdateDomainEndpointOptions_602811, base: "/",
    url: url_GetUpdateDomainEndpointOptions_602812,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateScalingParameters_602866 = ref object of OpenApiRestCall_601389
proc url_PostUpdateScalingParameters_602868(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateScalingParameters_602867(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602869 = query.getOrDefault("Action")
  valid_602869 = validateParameter(valid_602869, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_602869 != nil:
    section.add "Action", valid_602869
  var valid_602870 = query.getOrDefault("Version")
  valid_602870 = validateParameter(valid_602870, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602870 != nil:
    section.add "Version", valid_602870
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602871 = header.getOrDefault("X-Amz-Signature")
  valid_602871 = validateParameter(valid_602871, JString, required = false,
                                 default = nil)
  if valid_602871 != nil:
    section.add "X-Amz-Signature", valid_602871
  var valid_602872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Content-Sha256", valid_602872
  var valid_602873 = header.getOrDefault("X-Amz-Date")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Date", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-Credential")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Credential", valid_602874
  var valid_602875 = header.getOrDefault("X-Amz-Security-Token")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-Security-Token", valid_602875
  var valid_602876 = header.getOrDefault("X-Amz-Algorithm")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-Algorithm", valid_602876
  var valid_602877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "X-Amz-SignedHeaders", valid_602877
  result.add "header", section
  ## parameters in `formData` object:
  ##   ScalingParameters.DesiredReplicationCount: JString
  ##                                            : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ScalingParameters.DesiredPartitionCount: JString
  ##                                          : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   ScalingParameters.DesiredInstanceType: JString
  ##                                        : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  section = newJObject()
  var valid_602878 = formData.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_602878
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602879 = formData.getOrDefault("DomainName")
  valid_602879 = validateParameter(valid_602879, JString, required = true,
                                 default = nil)
  if valid_602879 != nil:
    section.add "DomainName", valid_602879
  var valid_602880 = formData.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_602880 = validateParameter(valid_602880, JString, required = false,
                                 default = nil)
  if valid_602880 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_602880
  var valid_602881 = formData.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_602881 = validateParameter(valid_602881, JString, required = false,
                                 default = nil)
  if valid_602881 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_602881
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602882: Call_PostUpdateScalingParameters_602866; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_602882.validator(path, query, header, formData, body)
  let scheme = call_602882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602882.url(scheme.get, call_602882.host, call_602882.base,
                         call_602882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602882, url, valid)

proc call*(call_602883: Call_PostUpdateScalingParameters_602866;
          DomainName: string;
          ScalingParametersDesiredReplicationCount: string = "";
          Action: string = "UpdateScalingParameters";
          ScalingParametersDesiredPartitionCount: string = "";
          ScalingParametersDesiredInstanceType: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateScalingParameters
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   ScalingParametersDesiredReplicationCount: string
  ##                                           : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   ScalingParametersDesiredPartitionCount: string
  ##                                         : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   ScalingParametersDesiredInstanceType: string
  ##                                       : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  ##   Version: string (required)
  var query_602884 = newJObject()
  var formData_602885 = newJObject()
  add(formData_602885, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(formData_602885, "DomainName", newJString(DomainName))
  add(query_602884, "Action", newJString(Action))
  add(formData_602885, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(formData_602885, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_602884, "Version", newJString(Version))
  result = call_602883.call(nil, query_602884, nil, formData_602885, nil)

var postUpdateScalingParameters* = Call_PostUpdateScalingParameters_602866(
    name: "postUpdateScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_PostUpdateScalingParameters_602867, base: "/",
    url: url_PostUpdateScalingParameters_602868,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateScalingParameters_602847 = ref object of OpenApiRestCall_601389
proc url_GetUpdateScalingParameters_602849(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateScalingParameters_602848(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ScalingParameters.DesiredPartitionCount: JString
  ##                                          : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ScalingParameters.DesiredInstanceType: JString
  ##                                        : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   ScalingParameters.DesiredReplicationCount: JString
  ##                                            : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  section = newJObject()
  var valid_602850 = query.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_602850 = validateParameter(valid_602850, JString, required = false,
                                 default = nil)
  if valid_602850 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_602850
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602851 = query.getOrDefault("DomainName")
  valid_602851 = validateParameter(valid_602851, JString, required = true,
                                 default = nil)
  if valid_602851 != nil:
    section.add "DomainName", valid_602851
  var valid_602852 = query.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_602852 = validateParameter(valid_602852, JString, required = false,
                                 default = nil)
  if valid_602852 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_602852
  var valid_602853 = query.getOrDefault("Action")
  valid_602853 = validateParameter(valid_602853, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_602853 != nil:
    section.add "Action", valid_602853
  var valid_602854 = query.getOrDefault("Version")
  valid_602854 = validateParameter(valid_602854, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602854 != nil:
    section.add "Version", valid_602854
  var valid_602855 = query.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_602855 = validateParameter(valid_602855, JString, required = false,
                                 default = nil)
  if valid_602855 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_602855
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602856 = header.getOrDefault("X-Amz-Signature")
  valid_602856 = validateParameter(valid_602856, JString, required = false,
                                 default = nil)
  if valid_602856 != nil:
    section.add "X-Amz-Signature", valid_602856
  var valid_602857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602857 = validateParameter(valid_602857, JString, required = false,
                                 default = nil)
  if valid_602857 != nil:
    section.add "X-Amz-Content-Sha256", valid_602857
  var valid_602858 = header.getOrDefault("X-Amz-Date")
  valid_602858 = validateParameter(valid_602858, JString, required = false,
                                 default = nil)
  if valid_602858 != nil:
    section.add "X-Amz-Date", valid_602858
  var valid_602859 = header.getOrDefault("X-Amz-Credential")
  valid_602859 = validateParameter(valid_602859, JString, required = false,
                                 default = nil)
  if valid_602859 != nil:
    section.add "X-Amz-Credential", valid_602859
  var valid_602860 = header.getOrDefault("X-Amz-Security-Token")
  valid_602860 = validateParameter(valid_602860, JString, required = false,
                                 default = nil)
  if valid_602860 != nil:
    section.add "X-Amz-Security-Token", valid_602860
  var valid_602861 = header.getOrDefault("X-Amz-Algorithm")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "X-Amz-Algorithm", valid_602861
  var valid_602862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "X-Amz-SignedHeaders", valid_602862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602863: Call_GetUpdateScalingParameters_602847; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_602863.validator(path, query, header, formData, body)
  let scheme = call_602863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602863.url(scheme.get, call_602863.host, call_602863.base,
                         call_602863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602863, url, valid)

proc call*(call_602864: Call_GetUpdateScalingParameters_602847; DomainName: string;
          ScalingParametersDesiredPartitionCount: string = "";
          ScalingParametersDesiredInstanceType: string = "";
          Action: string = "UpdateScalingParameters";
          Version: string = "2013-01-01";
          ScalingParametersDesiredReplicationCount: string = ""): Recallable =
  ## getUpdateScalingParameters
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   ScalingParametersDesiredPartitionCount: string
  ##                                         : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ScalingParametersDesiredInstanceType: string
  ##                                       : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ScalingParametersDesiredReplicationCount: string
  ##                                           : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  var query_602865 = newJObject()
  add(query_602865, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_602865, "DomainName", newJString(DomainName))
  add(query_602865, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_602865, "Action", newJString(Action))
  add(query_602865, "Version", newJString(Version))
  add(query_602865, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  result = call_602864.call(nil, query_602865, nil, nil, nil)

var getUpdateScalingParameters* = Call_GetUpdateScalingParameters_602847(
    name: "getUpdateScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_GetUpdateScalingParameters_602848, base: "/",
    url: url_GetUpdateScalingParameters_602849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_602903 = ref object of OpenApiRestCall_601389
proc url_PostUpdateServiceAccessPolicies_602905(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateServiceAccessPolicies_602904(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602906 = query.getOrDefault("Action")
  valid_602906 = validateParameter(valid_602906, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_602906 != nil:
    section.add "Action", valid_602906
  var valid_602907 = query.getOrDefault("Version")
  valid_602907 = validateParameter(valid_602907, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602907 != nil:
    section.add "Version", valid_602907
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602908 = header.getOrDefault("X-Amz-Signature")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-Signature", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Content-Sha256", valid_602909
  var valid_602910 = header.getOrDefault("X-Amz-Date")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Date", valid_602910
  var valid_602911 = header.getOrDefault("X-Amz-Credential")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-Credential", valid_602911
  var valid_602912 = header.getOrDefault("X-Amz-Security-Token")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "X-Amz-Security-Token", valid_602912
  var valid_602913 = header.getOrDefault("X-Amz-Algorithm")
  valid_602913 = validateParameter(valid_602913, JString, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "X-Amz-Algorithm", valid_602913
  var valid_602914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602914 = validateParameter(valid_602914, JString, required = false,
                                 default = nil)
  if valid_602914 != nil:
    section.add "X-Amz-SignedHeaders", valid_602914
  result.add "header", section
  ## parameters in `formData` object:
  ##   AccessPolicies: JString (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AccessPolicies` field"
  var valid_602915 = formData.getOrDefault("AccessPolicies")
  valid_602915 = validateParameter(valid_602915, JString, required = true,
                                 default = nil)
  if valid_602915 != nil:
    section.add "AccessPolicies", valid_602915
  var valid_602916 = formData.getOrDefault("DomainName")
  valid_602916 = validateParameter(valid_602916, JString, required = true,
                                 default = nil)
  if valid_602916 != nil:
    section.add "DomainName", valid_602916
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602917: Call_PostUpdateServiceAccessPolicies_602903;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_602917.validator(path, query, header, formData, body)
  let scheme = call_602917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602917.url(scheme.get, call_602917.host, call_602917.base,
                         call_602917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602917, url, valid)

proc call*(call_602918: Call_PostUpdateServiceAccessPolicies_602903;
          AccessPolicies: string; DomainName: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateServiceAccessPolicies
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ##   AccessPolicies: string (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602919 = newJObject()
  var formData_602920 = newJObject()
  add(formData_602920, "AccessPolicies", newJString(AccessPolicies))
  add(formData_602920, "DomainName", newJString(DomainName))
  add(query_602919, "Action", newJString(Action))
  add(query_602919, "Version", newJString(Version))
  result = call_602918.call(nil, query_602919, nil, formData_602920, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_602903(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_602904, base: "/",
    url: url_PostUpdateServiceAccessPolicies_602905,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_602886 = ref object of OpenApiRestCall_601389
proc url_GetUpdateServiceAccessPolicies_602888(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateServiceAccessPolicies_602887(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   AccessPolicies: JString (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602889 = query.getOrDefault("DomainName")
  valid_602889 = validateParameter(valid_602889, JString, required = true,
                                 default = nil)
  if valid_602889 != nil:
    section.add "DomainName", valid_602889
  var valid_602890 = query.getOrDefault("Action")
  valid_602890 = validateParameter(valid_602890, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_602890 != nil:
    section.add "Action", valid_602890
  var valid_602891 = query.getOrDefault("Version")
  valid_602891 = validateParameter(valid_602891, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_602891 != nil:
    section.add "Version", valid_602891
  var valid_602892 = query.getOrDefault("AccessPolicies")
  valid_602892 = validateParameter(valid_602892, JString, required = true,
                                 default = nil)
  if valid_602892 != nil:
    section.add "AccessPolicies", valid_602892
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602893 = header.getOrDefault("X-Amz-Signature")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-Signature", valid_602893
  var valid_602894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "X-Amz-Content-Sha256", valid_602894
  var valid_602895 = header.getOrDefault("X-Amz-Date")
  valid_602895 = validateParameter(valid_602895, JString, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "X-Amz-Date", valid_602895
  var valid_602896 = header.getOrDefault("X-Amz-Credential")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "X-Amz-Credential", valid_602896
  var valid_602897 = header.getOrDefault("X-Amz-Security-Token")
  valid_602897 = validateParameter(valid_602897, JString, required = false,
                                 default = nil)
  if valid_602897 != nil:
    section.add "X-Amz-Security-Token", valid_602897
  var valid_602898 = header.getOrDefault("X-Amz-Algorithm")
  valid_602898 = validateParameter(valid_602898, JString, required = false,
                                 default = nil)
  if valid_602898 != nil:
    section.add "X-Amz-Algorithm", valid_602898
  var valid_602899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602899 = validateParameter(valid_602899, JString, required = false,
                                 default = nil)
  if valid_602899 != nil:
    section.add "X-Amz-SignedHeaders", valid_602899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602900: Call_GetUpdateServiceAccessPolicies_602886; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_602900.validator(path, query, header, formData, body)
  let scheme = call_602900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602900.url(scheme.get, call_602900.host, call_602900.base,
                         call_602900.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602900, url, valid)

proc call*(call_602901: Call_GetUpdateServiceAccessPolicies_602886;
          DomainName: string; AccessPolicies: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## getUpdateServiceAccessPolicies
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AccessPolicies: string (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  var query_602902 = newJObject()
  add(query_602902, "DomainName", newJString(DomainName))
  add(query_602902, "Action", newJString(Action))
  add(query_602902, "Version", newJString(Version))
  add(query_602902, "AccessPolicies", newJString(AccessPolicies))
  result = call_602901.call(nil, query_602902, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_602886(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_602887, base: "/",
    url: url_GetUpdateServiceAccessPolicies_602888,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)

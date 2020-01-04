
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudSearch
## version: 2011-02-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudSearch Configuration Service</fullname> <p>You use the configuration service to create, configure, and manage search domains. Configuration service requests are submitted using the AWS Query protocol. AWS Query requests are HTTP or HTTPS requests submitted via HTTP GET or POST with a query parameter named Action.</p> <p>The endpoint for configuration service requests is region-specific: cloudsearch.<i>region</i>.amazonaws.com. For example, cloudsearch.us-east-1.amazonaws.com. For a current list of supported regions and endpoints, see <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html#cloudsearch_region">Regions and Endpoints</a>.</p>
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
  Call_PostCreateDomain_601998 = ref object of OpenApiRestCall_601389
proc url_PostCreateDomain_602000(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDomain_601999(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new search domain.
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
                                 default = newJString("CreateDomain"))
  if valid_602001 != nil:
    section.add "Action", valid_602001
  var valid_602002 = query.getOrDefault("Version")
  valid_602002 = validateParameter(valid_602002, JString, required = true,
                                 default = newJString("2011-02-01"))
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
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
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

proc call*(call_602011: Call_PostCreateDomain_601998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_602011.validator(path, query, header, formData, body)
  let scheme = call_602011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602011.url(scheme.get, call_602011.host, call_602011.base,
                         call_602011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602011, url, valid)

proc call*(call_602012: Call_PostCreateDomain_601998; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602013 = newJObject()
  var formData_602014 = newJObject()
  add(formData_602014, "DomainName", newJString(DomainName))
  add(query_602013, "Action", newJString(Action))
  add(query_602013, "Version", newJString(Version))
  result = call_602012.call(nil, query_602013, nil, formData_602014, nil)

var postCreateDomain* = Call_PostCreateDomain_601998(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_601999,
    base: "/", url: url_PostCreateDomain_602000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_601727 = ref object of OpenApiRestCall_601389
proc url_GetCreateDomain_601729(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDomain_601728(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
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
                                 default = newJString("CreateDomain"))
  if valid_601855 != nil:
    section.add "Action", valid_601855
  var valid_601856 = query.getOrDefault("Version")
  valid_601856 = validateParameter(valid_601856, JString, required = true,
                                 default = newJString("2011-02-01"))
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

proc call*(call_601886: Call_GetCreateDomain_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_601886.validator(path, query, header, formData, body)
  let scheme = call_601886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601886.url(scheme.get, call_601886.host, call_601886.base,
                         call_601886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601886, url, valid)

proc call*(call_601957: Call_GetCreateDomain_601727; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601958 = newJObject()
  add(query_601958, "DomainName", newJString(DomainName))
  add(query_601958, "Action", newJString(Action))
  add(query_601958, "Version", newJString(Version))
  result = call_601957.call(nil, query_601958, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_601727(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_601728,
    base: "/", url: url_GetCreateDomain_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_602037 = ref object of OpenApiRestCall_601389
proc url_PostDefineIndexField_602039(protocol: Scheme; host: string; base: string;
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

proc validate_PostDefineIndexField_602038(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
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
  var valid_602040 = query.getOrDefault("Action")
  valid_602040 = validateParameter(valid_602040, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_602040 != nil:
    section.add "Action", valid_602040
  var valid_602041 = query.getOrDefault("Version")
  valid_602041 = validateParameter(valid_602041, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602041 != nil:
    section.add "Version", valid_602041
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
  var valid_602042 = header.getOrDefault("X-Amz-Signature")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Signature", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Content-Sha256", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Date")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Date", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Credential")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Credential", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Security-Token")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Security-Token", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Algorithm")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Algorithm", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-SignedHeaders", valid_602048
  result.add "header", section
  ## parameters in `formData` object:
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexField.TextOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  var valid_602049 = formData.getOrDefault("IndexField.UIntOptions")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "IndexField.UIntOptions", valid_602049
  var valid_602050 = formData.getOrDefault("IndexField.SourceAttributes")
  valid_602050 = validateParameter(valid_602050, JArray, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "IndexField.SourceAttributes", valid_602050
  var valid_602051 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "IndexField.IndexFieldType", valid_602051
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602052 = formData.getOrDefault("DomainName")
  valid_602052 = validateParameter(valid_602052, JString, required = true,
                                 default = nil)
  if valid_602052 != nil:
    section.add "DomainName", valid_602052
  var valid_602053 = formData.getOrDefault("IndexField.TextOptions")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "IndexField.TextOptions", valid_602053
  var valid_602054 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "IndexField.LiteralOptions", valid_602054
  var valid_602055 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "IndexField.IndexFieldName", valid_602055
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602056: Call_PostDefineIndexField_602037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_602056.validator(path, query, header, formData, body)
  let scheme = call_602056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602056.url(scheme.get, call_602056.host, call_602056.base,
                         call_602056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602056, url, valid)

proc call*(call_602057: Call_PostDefineIndexField_602037; DomainName: string;
          IndexFieldUIntOptions: string = "";
          IndexFieldSourceAttributes: JsonNode = nil;
          IndexFieldIndexFieldType: string = ""; IndexFieldTextOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          Action: string = "DefineIndexField";
          IndexFieldIndexFieldName: string = ""; Version: string = "2011-02-01"): Recallable =
  ## postDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   Action: string (required)
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  var query_602058 = newJObject()
  var formData_602059 = newJObject()
  add(formData_602059, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  if IndexFieldSourceAttributes != nil:
    formData_602059.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(formData_602059, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(formData_602059, "DomainName", newJString(DomainName))
  add(formData_602059, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_602059, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_602058, "Action", newJString(Action))
  add(formData_602059, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_602058, "Version", newJString(Version))
  result = call_602057.call(nil, query_602058, nil, formData_602059, nil)

var postDefineIndexField* = Call_PostDefineIndexField_602037(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_602038, base: "/",
    url: url_PostDefineIndexField_602039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_602015 = ref object of OpenApiRestCall_601389
proc url_GetDefineIndexField_602017(protocol: Scheme; host: string; base: string;
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

proc validate_GetDefineIndexField_602016(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexField.TextOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   Action: JString (required)
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   Version: JString (required)
  section = newJObject()
  var valid_602018 = query.getOrDefault("IndexField.TextOptions")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "IndexField.TextOptions", valid_602018
  var valid_602019 = query.getOrDefault("IndexField.IndexFieldType")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "IndexField.IndexFieldType", valid_602019
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602020 = query.getOrDefault("DomainName")
  valid_602020 = validateParameter(valid_602020, JString, required = true,
                                 default = nil)
  if valid_602020 != nil:
    section.add "DomainName", valid_602020
  var valid_602021 = query.getOrDefault("IndexField.IndexFieldName")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "IndexField.IndexFieldName", valid_602021
  var valid_602022 = query.getOrDefault("IndexField.UIntOptions")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "IndexField.UIntOptions", valid_602022
  var valid_602023 = query.getOrDefault("IndexField.SourceAttributes")
  valid_602023 = validateParameter(valid_602023, JArray, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "IndexField.SourceAttributes", valid_602023
  var valid_602024 = query.getOrDefault("Action")
  valid_602024 = validateParameter(valid_602024, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_602024 != nil:
    section.add "Action", valid_602024
  var valid_602025 = query.getOrDefault("IndexField.LiteralOptions")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "IndexField.LiteralOptions", valid_602025
  var valid_602026 = query.getOrDefault("Version")
  valid_602026 = validateParameter(valid_602026, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602026 != nil:
    section.add "Version", valid_602026
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
  var valid_602027 = header.getOrDefault("X-Amz-Signature")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Signature", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Content-Sha256", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Date")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Date", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Credential")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Credential", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Security-Token")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Security-Token", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Algorithm")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Algorithm", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-SignedHeaders", valid_602033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602034: Call_GetDefineIndexField_602015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_602034.validator(path, query, header, formData, body)
  let scheme = call_602034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602034.url(scheme.get, call_602034.host, call_602034.base,
                         call_602034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602034, url, valid)

proc call*(call_602035: Call_GetDefineIndexField_602015; DomainName: string;
          IndexFieldTextOptions: string = ""; IndexFieldIndexFieldType: string = "";
          IndexFieldIndexFieldName: string = ""; IndexFieldUIntOptions: string = "";
          IndexFieldSourceAttributes: JsonNode = nil;
          Action: string = "DefineIndexField";
          IndexFieldLiteralOptions: string = ""; Version: string = "2011-02-01"): Recallable =
  ## getDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   Action: string (required)
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   Version: string (required)
  var query_602036 = newJObject()
  add(query_602036, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_602036, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_602036, "DomainName", newJString(DomainName))
  add(query_602036, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_602036, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  if IndexFieldSourceAttributes != nil:
    query_602036.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(query_602036, "Action", newJString(Action))
  add(query_602036, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_602036, "Version", newJString(Version))
  result = call_602035.call(nil, query_602036, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_602015(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_602016, base: "/",
    url: url_GetDefineIndexField_602017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineRankExpression_602078 = ref object of OpenApiRestCall_601389
proc url_PostDefineRankExpression_602080(protocol: Scheme; host: string;
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

proc validate_PostDefineRankExpression_602079(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
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
  var valid_602081 = query.getOrDefault("Action")
  valid_602081 = validateParameter(valid_602081, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_602081 != nil:
    section.add "Action", valid_602081
  var valid_602082 = query.getOrDefault("Version")
  valid_602082 = validateParameter(valid_602082, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602082 != nil:
    section.add "Version", valid_602082
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
  var valid_602083 = header.getOrDefault("X-Amz-Signature")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Signature", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Content-Sha256", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Date")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Date", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Credential")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Credential", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Security-Token")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Security-Token", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Algorithm")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Algorithm", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-SignedHeaders", valid_602089
  result.add "header", section
  ## parameters in `formData` object:
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  var valid_602090 = formData.getOrDefault("RankExpression.RankName")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "RankExpression.RankName", valid_602090
  var valid_602091 = formData.getOrDefault("RankExpression.RankExpression")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "RankExpression.RankExpression", valid_602091
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602092 = formData.getOrDefault("DomainName")
  valid_602092 = validateParameter(valid_602092, JString, required = true,
                                 default = nil)
  if valid_602092 != nil:
    section.add "DomainName", valid_602092
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602093: Call_PostDefineRankExpression_602078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_602093.validator(path, query, header, formData, body)
  let scheme = call_602093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602093.url(scheme.get, call_602093.host, call_602093.base,
                         call_602093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602093, url, valid)

proc call*(call_602094: Call_PostDefineRankExpression_602078; DomainName: string;
          RankExpressionRankName: string = "";
          RankExpressionRankExpression: string = "";
          Action: string = "DefineRankExpression"; Version: string = "2011-02-01"): Recallable =
  ## postDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602095 = newJObject()
  var formData_602096 = newJObject()
  add(formData_602096, "RankExpression.RankName",
      newJString(RankExpressionRankName))
  add(formData_602096, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(formData_602096, "DomainName", newJString(DomainName))
  add(query_602095, "Action", newJString(Action))
  add(query_602095, "Version", newJString(Version))
  result = call_602094.call(nil, query_602095, nil, formData_602096, nil)

var postDefineRankExpression* = Call_PostDefineRankExpression_602078(
    name: "postDefineRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_PostDefineRankExpression_602079, base: "/",
    url: url_PostDefineRankExpression_602080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineRankExpression_602060 = ref object of OpenApiRestCall_601389
proc url_GetDefineRankExpression_602062(protocol: Scheme; host: string; base: string;
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

proc validate_GetDefineRankExpression_602061(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602063 = query.getOrDefault("DomainName")
  valid_602063 = validateParameter(valid_602063, JString, required = true,
                                 default = nil)
  if valid_602063 != nil:
    section.add "DomainName", valid_602063
  var valid_602064 = query.getOrDefault("Action")
  valid_602064 = validateParameter(valid_602064, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_602064 != nil:
    section.add "Action", valid_602064
  var valid_602065 = query.getOrDefault("Version")
  valid_602065 = validateParameter(valid_602065, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602065 != nil:
    section.add "Version", valid_602065
  var valid_602066 = query.getOrDefault("RankExpression.RankName")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "RankExpression.RankName", valid_602066
  var valid_602067 = query.getOrDefault("RankExpression.RankExpression")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "RankExpression.RankExpression", valid_602067
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
  var valid_602068 = header.getOrDefault("X-Amz-Signature")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Signature", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Content-Sha256", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Date")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Date", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Credential")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Credential", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Security-Token")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Security-Token", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Algorithm")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Algorithm", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-SignedHeaders", valid_602074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602075: Call_GetDefineRankExpression_602060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_602075.validator(path, query, header, formData, body)
  let scheme = call_602075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602075.url(scheme.get, call_602075.host, call_602075.base,
                         call_602075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602075, url, valid)

proc call*(call_602076: Call_GetDefineRankExpression_602060; DomainName: string;
          Action: string = "DefineRankExpression"; Version: string = "2011-02-01";
          RankExpressionRankName: string = "";
          RankExpressionRankExpression: string = ""): Recallable =
  ## getDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  var query_602077 = newJObject()
  add(query_602077, "DomainName", newJString(DomainName))
  add(query_602077, "Action", newJString(Action))
  add(query_602077, "Version", newJString(Version))
  add(query_602077, "RankExpression.RankName", newJString(RankExpressionRankName))
  add(query_602077, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  result = call_602076.call(nil, query_602077, nil, nil, nil)

var getDefineRankExpression* = Call_GetDefineRankExpression_602060(
    name: "getDefineRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_GetDefineRankExpression_602061, base: "/",
    url: url_GetDefineRankExpression_602062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_602113 = ref object of OpenApiRestCall_601389
proc url_PostDeleteDomain_602115(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDomain_602114(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data.
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
  var valid_602116 = query.getOrDefault("Action")
  valid_602116 = validateParameter(valid_602116, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_602116 != nil:
    section.add "Action", valid_602116
  var valid_602117 = query.getOrDefault("Version")
  valid_602117 = validateParameter(valid_602117, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602117 != nil:
    section.add "Version", valid_602117
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
  var valid_602118 = header.getOrDefault("X-Amz-Signature")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Signature", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Content-Sha256", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Date")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Date", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Credential")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Credential", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Security-Token")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Security-Token", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Algorithm")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Algorithm", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-SignedHeaders", valid_602124
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602125 = formData.getOrDefault("DomainName")
  valid_602125 = validateParameter(valid_602125, JString, required = true,
                                 default = nil)
  if valid_602125 != nil:
    section.add "DomainName", valid_602125
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602126: Call_PostDeleteDomain_602113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_602126.validator(path, query, header, formData, body)
  let scheme = call_602126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602126.url(scheme.get, call_602126.host, call_602126.base,
                         call_602126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602126, url, valid)

proc call*(call_602127: Call_PostDeleteDomain_602113; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602128 = newJObject()
  var formData_602129 = newJObject()
  add(formData_602129, "DomainName", newJString(DomainName))
  add(query_602128, "Action", newJString(Action))
  add(query_602128, "Version", newJString(Version))
  result = call_602127.call(nil, query_602128, nil, formData_602129, nil)

var postDeleteDomain* = Call_PostDeleteDomain_602113(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_602114,
    base: "/", url: url_PostDeleteDomain_602115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_602097 = ref object of OpenApiRestCall_601389
proc url_GetDeleteDomain_602099(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDomain_602098(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602100 = query.getOrDefault("DomainName")
  valid_602100 = validateParameter(valid_602100, JString, required = true,
                                 default = nil)
  if valid_602100 != nil:
    section.add "DomainName", valid_602100
  var valid_602101 = query.getOrDefault("Action")
  valid_602101 = validateParameter(valid_602101, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_602101 != nil:
    section.add "Action", valid_602101
  var valid_602102 = query.getOrDefault("Version")
  valid_602102 = validateParameter(valid_602102, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602102 != nil:
    section.add "Version", valid_602102
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
  var valid_602103 = header.getOrDefault("X-Amz-Signature")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Signature", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Content-Sha256", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Date")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Date", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Credential")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Credential", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Security-Token")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Security-Token", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Algorithm")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Algorithm", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-SignedHeaders", valid_602109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602110: Call_GetDeleteDomain_602097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_602110.validator(path, query, header, formData, body)
  let scheme = call_602110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602110.url(scheme.get, call_602110.host, call_602110.base,
                         call_602110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602110, url, valid)

proc call*(call_602111: Call_GetDeleteDomain_602097; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602112 = newJObject()
  add(query_602112, "DomainName", newJString(DomainName))
  add(query_602112, "Action", newJString(Action))
  add(query_602112, "Version", newJString(Version))
  result = call_602111.call(nil, query_602112, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_602097(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_602098,
    base: "/", url: url_GetDeleteDomain_602099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_602147 = ref object of OpenApiRestCall_601389
proc url_PostDeleteIndexField_602149(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteIndexField_602148(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an <code>IndexField</code> from the search domain.
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
  var valid_602150 = query.getOrDefault("Action")
  valid_602150 = validateParameter(valid_602150, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_602150 != nil:
    section.add "Action", valid_602150
  var valid_602151 = query.getOrDefault("Version")
  valid_602151 = validateParameter(valid_602151, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602151 != nil:
    section.add "Version", valid_602151
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
  var valid_602152 = header.getOrDefault("X-Amz-Signature")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Signature", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Content-Sha256", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Date")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Date", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Credential")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Credential", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Security-Token")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Security-Token", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Algorithm")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Algorithm", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-SignedHeaders", valid_602158
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602159 = formData.getOrDefault("DomainName")
  valid_602159 = validateParameter(valid_602159, JString, required = true,
                                 default = nil)
  if valid_602159 != nil:
    section.add "DomainName", valid_602159
  var valid_602160 = formData.getOrDefault("IndexFieldName")
  valid_602160 = validateParameter(valid_602160, JString, required = true,
                                 default = nil)
  if valid_602160 != nil:
    section.add "IndexFieldName", valid_602160
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602161: Call_PostDeleteIndexField_602147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_602161.validator(path, query, header, formData, body)
  let scheme = call_602161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602161.url(scheme.get, call_602161.host, call_602161.base,
                         call_602161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602161, url, valid)

proc call*(call_602162: Call_PostDeleteIndexField_602147; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2011-02-01"): Recallable =
  ## postDeleteIndexField
  ## Removes an <code>IndexField</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: string (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602163 = newJObject()
  var formData_602164 = newJObject()
  add(formData_602164, "DomainName", newJString(DomainName))
  add(formData_602164, "IndexFieldName", newJString(IndexFieldName))
  add(query_602163, "Action", newJString(Action))
  add(query_602163, "Version", newJString(Version))
  result = call_602162.call(nil, query_602163, nil, formData_602164, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_602147(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_602148, base: "/",
    url: url_PostDeleteIndexField_602149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_602130 = ref object of OpenApiRestCall_601389
proc url_GetDeleteIndexField_602132(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteIndexField_602131(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602133 = query.getOrDefault("DomainName")
  valid_602133 = validateParameter(valid_602133, JString, required = true,
                                 default = nil)
  if valid_602133 != nil:
    section.add "DomainName", valid_602133
  var valid_602134 = query.getOrDefault("Action")
  valid_602134 = validateParameter(valid_602134, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_602134 != nil:
    section.add "Action", valid_602134
  var valid_602135 = query.getOrDefault("IndexFieldName")
  valid_602135 = validateParameter(valid_602135, JString, required = true,
                                 default = nil)
  if valid_602135 != nil:
    section.add "IndexFieldName", valid_602135
  var valid_602136 = query.getOrDefault("Version")
  valid_602136 = validateParameter(valid_602136, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602136 != nil:
    section.add "Version", valid_602136
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
  var valid_602137 = header.getOrDefault("X-Amz-Signature")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Signature", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Content-Sha256", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Date")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Date", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Credential")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Credential", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Security-Token")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Security-Token", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Algorithm")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Algorithm", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-SignedHeaders", valid_602143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602144: Call_GetDeleteIndexField_602130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_602144.validator(path, query, header, formData, body)
  let scheme = call_602144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602144.url(scheme.get, call_602144.host, call_602144.base,
                         call_602144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602144, url, valid)

proc call*(call_602145: Call_GetDeleteIndexField_602130; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteIndexField
  ## Removes an <code>IndexField</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   IndexFieldName: string (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  var query_602146 = newJObject()
  add(query_602146, "DomainName", newJString(DomainName))
  add(query_602146, "Action", newJString(Action))
  add(query_602146, "IndexFieldName", newJString(IndexFieldName))
  add(query_602146, "Version", newJString(Version))
  result = call_602145.call(nil, query_602146, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_602130(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_602131, base: "/",
    url: url_GetDeleteIndexField_602132, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRankExpression_602182 = ref object of OpenApiRestCall_601389
proc url_PostDeleteRankExpression_602184(protocol: Scheme; host: string;
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

proc validate_PostDeleteRankExpression_602183(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a <code>RankExpression</code> from the search domain.
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
  var valid_602185 = query.getOrDefault("Action")
  valid_602185 = validateParameter(valid_602185, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_602185 != nil:
    section.add "Action", valid_602185
  var valid_602186 = query.getOrDefault("Version")
  valid_602186 = validateParameter(valid_602186, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602186 != nil:
    section.add "Version", valid_602186
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
  var valid_602187 = header.getOrDefault("X-Amz-Signature")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Signature", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Content-Sha256", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Date")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Date", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Credential")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Credential", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Security-Token")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Security-Token", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Algorithm")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Algorithm", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-SignedHeaders", valid_602193
  result.add "header", section
  ## parameters in `formData` object:
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RankName` field"
  var valid_602194 = formData.getOrDefault("RankName")
  valid_602194 = validateParameter(valid_602194, JString, required = true,
                                 default = nil)
  if valid_602194 != nil:
    section.add "RankName", valid_602194
  var valid_602195 = formData.getOrDefault("DomainName")
  valid_602195 = validateParameter(valid_602195, JString, required = true,
                                 default = nil)
  if valid_602195 != nil:
    section.add "DomainName", valid_602195
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602196: Call_PostDeleteRankExpression_602182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_602196.validator(path, query, header, formData, body)
  let scheme = call_602196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602196.url(scheme.get, call_602196.host, call_602196.base,
                         call_602196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602196, url, valid)

proc call*(call_602197: Call_PostDeleteRankExpression_602182; RankName: string;
          DomainName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## postDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602198 = newJObject()
  var formData_602199 = newJObject()
  add(formData_602199, "RankName", newJString(RankName))
  add(formData_602199, "DomainName", newJString(DomainName))
  add(query_602198, "Action", newJString(Action))
  add(query_602198, "Version", newJString(Version))
  result = call_602197.call(nil, query_602198, nil, formData_602199, nil)

var postDeleteRankExpression* = Call_PostDeleteRankExpression_602182(
    name: "postDeleteRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_PostDeleteRankExpression_602183, base: "/",
    url: url_PostDeleteRankExpression_602184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRankExpression_602165 = ref object of OpenApiRestCall_601389
proc url_GetDeleteRankExpression_602167(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteRankExpression_602166(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602168 = query.getOrDefault("DomainName")
  valid_602168 = validateParameter(valid_602168, JString, required = true,
                                 default = nil)
  if valid_602168 != nil:
    section.add "DomainName", valid_602168
  var valid_602169 = query.getOrDefault("RankName")
  valid_602169 = validateParameter(valid_602169, JString, required = true,
                                 default = nil)
  if valid_602169 != nil:
    section.add "RankName", valid_602169
  var valid_602170 = query.getOrDefault("Action")
  valid_602170 = validateParameter(valid_602170, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_602170 != nil:
    section.add "Action", valid_602170
  var valid_602171 = query.getOrDefault("Version")
  valid_602171 = validateParameter(valid_602171, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602171 != nil:
    section.add "Version", valid_602171
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
  var valid_602172 = header.getOrDefault("X-Amz-Signature")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Signature", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Content-Sha256", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Date")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Date", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Credential")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Credential", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Security-Token")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Security-Token", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Algorithm")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Algorithm", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-SignedHeaders", valid_602178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602179: Call_GetDeleteRankExpression_602165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_602179.validator(path, query, header, formData, body)
  let scheme = call_602179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602179.url(scheme.get, call_602179.host, call_602179.base,
                         call_602179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602179, url, valid)

proc call*(call_602180: Call_GetDeleteRankExpression_602165; DomainName: string;
          RankName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602181 = newJObject()
  add(query_602181, "DomainName", newJString(DomainName))
  add(query_602181, "RankName", newJString(RankName))
  add(query_602181, "Action", newJString(Action))
  add(query_602181, "Version", newJString(Version))
  result = call_602180.call(nil, query_602181, nil, nil, nil)

var getDeleteRankExpression* = Call_GetDeleteRankExpression_602165(
    name: "getDeleteRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_GetDeleteRankExpression_602166, base: "/",
    url: url_GetDeleteRankExpression_602167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_602216 = ref object of OpenApiRestCall_601389
proc url_PostDescribeAvailabilityOptions_602218(protocol: Scheme; host: string;
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

proc validate_PostDescribeAvailabilityOptions_602217(path: JsonNode;
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
  var valid_602219 = query.getOrDefault("Action")
  valid_602219 = validateParameter(valid_602219, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_602219 != nil:
    section.add "Action", valid_602219
  var valid_602220 = query.getOrDefault("Version")
  valid_602220 = validateParameter(valid_602220, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602220 != nil:
    section.add "Version", valid_602220
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
  var valid_602221 = header.getOrDefault("X-Amz-Signature")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Signature", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Content-Sha256", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Date")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Date", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Credential")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Credential", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Security-Token")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Security-Token", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Algorithm")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Algorithm", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-SignedHeaders", valid_602227
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602228 = formData.getOrDefault("DomainName")
  valid_602228 = validateParameter(valid_602228, JString, required = true,
                                 default = nil)
  if valid_602228 != nil:
    section.add "DomainName", valid_602228
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602229: Call_PostDescribeAvailabilityOptions_602216;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602229.validator(path, query, header, formData, body)
  let scheme = call_602229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602229.url(scheme.get, call_602229.host, call_602229.base,
                         call_602229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602229, url, valid)

proc call*(call_602230: Call_PostDescribeAvailabilityOptions_602216;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602231 = newJObject()
  var formData_602232 = newJObject()
  add(formData_602232, "DomainName", newJString(DomainName))
  add(query_602231, "Action", newJString(Action))
  add(query_602231, "Version", newJString(Version))
  result = call_602230.call(nil, query_602231, nil, formData_602232, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_602216(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_602217, base: "/",
    url: url_PostDescribeAvailabilityOptions_602218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_602200 = ref object of OpenApiRestCall_601389
proc url_GetDescribeAvailabilityOptions_602202(protocol: Scheme; host: string;
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

proc validate_GetDescribeAvailabilityOptions_602201(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602203 = query.getOrDefault("DomainName")
  valid_602203 = validateParameter(valid_602203, JString, required = true,
                                 default = nil)
  if valid_602203 != nil:
    section.add "DomainName", valid_602203
  var valid_602204 = query.getOrDefault("Action")
  valid_602204 = validateParameter(valid_602204, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_602204 != nil:
    section.add "Action", valid_602204
  var valid_602205 = query.getOrDefault("Version")
  valid_602205 = validateParameter(valid_602205, JString, required = true,
                                 default = newJString("2011-02-01"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602213: Call_GetDescribeAvailabilityOptions_602200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602213.validator(path, query, header, formData, body)
  let scheme = call_602213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602213.url(scheme.get, call_602213.host, call_602213.base,
                         call_602213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602213, url, valid)

proc call*(call_602214: Call_GetDescribeAvailabilityOptions_602200;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602215 = newJObject()
  add(query_602215, "DomainName", newJString(DomainName))
  add(query_602215, "Action", newJString(Action))
  add(query_602215, "Version", newJString(Version))
  result = call_602214.call(nil, query_602215, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_602200(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_602201, base: "/",
    url: url_GetDescribeAvailabilityOptions_602202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDefaultSearchField_602249 = ref object of OpenApiRestCall_601389
proc url_PostDescribeDefaultSearchField_602251(protocol: Scheme; host: string;
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

proc validate_PostDescribeDefaultSearchField_602250(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the default search field configured for the search domain.
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
  var valid_602252 = query.getOrDefault("Action")
  valid_602252 = validateParameter(valid_602252, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_602252 != nil:
    section.add "Action", valid_602252
  var valid_602253 = query.getOrDefault("Version")
  valid_602253 = validateParameter(valid_602253, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602253 != nil:
    section.add "Version", valid_602253
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
  var valid_602254 = header.getOrDefault("X-Amz-Signature")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Signature", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Content-Sha256", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Date")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Date", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Credential")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Credential", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Security-Token")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Security-Token", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Algorithm")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Algorithm", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-SignedHeaders", valid_602260
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602261 = formData.getOrDefault("DomainName")
  valid_602261 = validateParameter(valid_602261, JString, required = true,
                                 default = nil)
  if valid_602261 != nil:
    section.add "DomainName", valid_602261
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602262: Call_PostDescribeDefaultSearchField_602249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_602262.validator(path, query, header, formData, body)
  let scheme = call_602262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602262.url(scheme.get, call_602262.host, call_602262.base,
                         call_602262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602262, url, valid)

proc call*(call_602263: Call_PostDescribeDefaultSearchField_602249;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602264 = newJObject()
  var formData_602265 = newJObject()
  add(formData_602265, "DomainName", newJString(DomainName))
  add(query_602264, "Action", newJString(Action))
  add(query_602264, "Version", newJString(Version))
  result = call_602263.call(nil, query_602264, nil, formData_602265, nil)

var postDescribeDefaultSearchField* = Call_PostDescribeDefaultSearchField_602249(
    name: "postDescribeDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_PostDescribeDefaultSearchField_602250, base: "/",
    url: url_PostDescribeDefaultSearchField_602251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDefaultSearchField_602233 = ref object of OpenApiRestCall_601389
proc url_GetDescribeDefaultSearchField_602235(protocol: Scheme; host: string;
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

proc validate_GetDescribeDefaultSearchField_602234(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the default search field configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602236 = query.getOrDefault("DomainName")
  valid_602236 = validateParameter(valid_602236, JString, required = true,
                                 default = nil)
  if valid_602236 != nil:
    section.add "DomainName", valid_602236
  var valid_602237 = query.getOrDefault("Action")
  valid_602237 = validateParameter(valid_602237, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_602237 != nil:
    section.add "Action", valid_602237
  var valid_602238 = query.getOrDefault("Version")
  valid_602238 = validateParameter(valid_602238, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602238 != nil:
    section.add "Version", valid_602238
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
  var valid_602239 = header.getOrDefault("X-Amz-Signature")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Signature", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Content-Sha256", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Date")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Date", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Credential")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Credential", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Security-Token")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Security-Token", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Algorithm")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Algorithm", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-SignedHeaders", valid_602245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602246: Call_GetDescribeDefaultSearchField_602233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_602246.validator(path, query, header, formData, body)
  let scheme = call_602246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602246.url(scheme.get, call_602246.host, call_602246.base,
                         call_602246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602246, url, valid)

proc call*(call_602247: Call_GetDescribeDefaultSearchField_602233;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602248 = newJObject()
  add(query_602248, "DomainName", newJString(DomainName))
  add(query_602248, "Action", newJString(Action))
  add(query_602248, "Version", newJString(Version))
  result = call_602247.call(nil, query_602248, nil, nil, nil)

var getDescribeDefaultSearchField* = Call_GetDescribeDefaultSearchField_602233(
    name: "getDescribeDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_GetDescribeDefaultSearchField_602234, base: "/",
    url: url_GetDescribeDefaultSearchField_602235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_602282 = ref object of OpenApiRestCall_601389
proc url_PostDescribeDomains_602284(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDomains_602283(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
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
  var valid_602285 = query.getOrDefault("Action")
  valid_602285 = validateParameter(valid_602285, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_602285 != nil:
    section.add "Action", valid_602285
  var valid_602286 = query.getOrDefault("Version")
  valid_602286 = validateParameter(valid_602286, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602286 != nil:
    section.add "Version", valid_602286
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
  var valid_602287 = header.getOrDefault("X-Amz-Signature")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Signature", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Content-Sha256", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Date")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Date", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-Credential")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Credential", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Security-Token")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Security-Token", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-Algorithm")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-Algorithm", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-SignedHeaders", valid_602293
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_602294 = formData.getOrDefault("DomainNames")
  valid_602294 = validateParameter(valid_602294, JArray, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "DomainNames", valid_602294
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602295: Call_PostDescribeDomains_602282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_602295.validator(path, query, header, formData, body)
  let scheme = call_602295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602295.url(scheme.get, call_602295.host, call_602295.base,
                         call_602295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602295, url, valid)

proc call*(call_602296: Call_PostDescribeDomains_602282;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602297 = newJObject()
  var formData_602298 = newJObject()
  if DomainNames != nil:
    formData_602298.add "DomainNames", DomainNames
  add(query_602297, "Action", newJString(Action))
  add(query_602297, "Version", newJString(Version))
  result = call_602296.call(nil, query_602297, nil, formData_602298, nil)

var postDescribeDomains* = Call_PostDescribeDomains_602282(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_602283, base: "/",
    url: url_PostDescribeDomains_602284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_602266 = ref object of OpenApiRestCall_601389
proc url_GetDescribeDomains_602268(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDomains_602267(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
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
  var valid_602269 = query.getOrDefault("DomainNames")
  valid_602269 = validateParameter(valid_602269, JArray, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "DomainNames", valid_602269
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602270 = query.getOrDefault("Action")
  valid_602270 = validateParameter(valid_602270, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_602270 != nil:
    section.add "Action", valid_602270
  var valid_602271 = query.getOrDefault("Version")
  valid_602271 = validateParameter(valid_602271, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602271 != nil:
    section.add "Version", valid_602271
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
  var valid_602272 = header.getOrDefault("X-Amz-Signature")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Signature", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Content-Sha256", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Date")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Date", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Credential")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Credential", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Security-Token")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Security-Token", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Algorithm")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Algorithm", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-SignedHeaders", valid_602278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602279: Call_GetDescribeDomains_602266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_602279.validator(path, query, header, formData, body)
  let scheme = call_602279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602279.url(scheme.get, call_602279.host, call_602279.base,
                         call_602279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602279, url, valid)

proc call*(call_602280: Call_GetDescribeDomains_602266;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602281 = newJObject()
  if DomainNames != nil:
    query_602281.add "DomainNames", DomainNames
  add(query_602281, "Action", newJString(Action))
  add(query_602281, "Version", newJString(Version))
  result = call_602280.call(nil, query_602281, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_602266(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_602267, base: "/",
    url: url_GetDescribeDomains_602268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_602316 = ref object of OpenApiRestCall_601389
proc url_PostDescribeIndexFields_602318(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeIndexFields_602317(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
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
  var valid_602319 = query.getOrDefault("Action")
  valid_602319 = validateParameter(valid_602319, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_602319 != nil:
    section.add "Action", valid_602319
  var valid_602320 = query.getOrDefault("Version")
  valid_602320 = validateParameter(valid_602320, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602320 != nil:
    section.add "Version", valid_602320
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
  var valid_602321 = header.getOrDefault("X-Amz-Signature")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Signature", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Content-Sha256", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Date")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Date", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-Credential")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Credential", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Security-Token")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Security-Token", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Algorithm")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Algorithm", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-SignedHeaders", valid_602327
  result.add "header", section
  ## parameters in `formData` object:
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  var valid_602328 = formData.getOrDefault("FieldNames")
  valid_602328 = validateParameter(valid_602328, JArray, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "FieldNames", valid_602328
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602329 = formData.getOrDefault("DomainName")
  valid_602329 = validateParameter(valid_602329, JString, required = true,
                                 default = nil)
  if valid_602329 != nil:
    section.add "DomainName", valid_602329
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602330: Call_PostDescribeIndexFields_602316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_602330.validator(path, query, header, formData, body)
  let scheme = call_602330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602330.url(scheme.get, call_602330.host, call_602330.base,
                         call_602330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602330, url, valid)

proc call*(call_602331: Call_PostDescribeIndexFields_602316; DomainName: string;
          FieldNames: JsonNode = nil; Action: string = "DescribeIndexFields";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602332 = newJObject()
  var formData_602333 = newJObject()
  if FieldNames != nil:
    formData_602333.add "FieldNames", FieldNames
  add(formData_602333, "DomainName", newJString(DomainName))
  add(query_602332, "Action", newJString(Action))
  add(query_602332, "Version", newJString(Version))
  result = call_602331.call(nil, query_602332, nil, formData_602333, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_602316(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_602317, base: "/",
    url: url_PostDescribeIndexFields_602318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_602299 = ref object of OpenApiRestCall_601389
proc url_GetDescribeIndexFields_602301(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeIndexFields_602300(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602302 = query.getOrDefault("DomainName")
  valid_602302 = validateParameter(valid_602302, JString, required = true,
                                 default = nil)
  if valid_602302 != nil:
    section.add "DomainName", valid_602302
  var valid_602303 = query.getOrDefault("Action")
  valid_602303 = validateParameter(valid_602303, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_602303 != nil:
    section.add "Action", valid_602303
  var valid_602304 = query.getOrDefault("Version")
  valid_602304 = validateParameter(valid_602304, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602304 != nil:
    section.add "Version", valid_602304
  var valid_602305 = query.getOrDefault("FieldNames")
  valid_602305 = validateParameter(valid_602305, JArray, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "FieldNames", valid_602305
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
  var valid_602306 = header.getOrDefault("X-Amz-Signature")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-Signature", valid_602306
  var valid_602307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-Content-Sha256", valid_602307
  var valid_602308 = header.getOrDefault("X-Amz-Date")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Date", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-Credential")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-Credential", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-Security-Token")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Security-Token", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Algorithm")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Algorithm", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-SignedHeaders", valid_602312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602313: Call_GetDescribeIndexFields_602299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_602313.validator(path, query, header, formData, body)
  let scheme = call_602313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602313.url(scheme.get, call_602313.host, call_602313.base,
                         call_602313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602313, url, valid)

proc call*(call_602314: Call_GetDescribeIndexFields_602299; DomainName: string;
          Action: string = "DescribeIndexFields"; Version: string = "2011-02-01";
          FieldNames: JsonNode = nil): Recallable =
  ## getDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  var query_602315 = newJObject()
  add(query_602315, "DomainName", newJString(DomainName))
  add(query_602315, "Action", newJString(Action))
  add(query_602315, "Version", newJString(Version))
  if FieldNames != nil:
    query_602315.add "FieldNames", FieldNames
  result = call_602314.call(nil, query_602315, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_602299(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_602300, base: "/",
    url: url_GetDescribeIndexFields_602301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRankExpressions_602351 = ref object of OpenApiRestCall_601389
proc url_PostDescribeRankExpressions_602353(protocol: Scheme; host: string;
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

proc validate_PostDescribeRankExpressions_602352(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
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
  var valid_602354 = query.getOrDefault("Action")
  valid_602354 = validateParameter(valid_602354, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_602354 != nil:
    section.add "Action", valid_602354
  var valid_602355 = query.getOrDefault("Version")
  valid_602355 = validateParameter(valid_602355, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602355 != nil:
    section.add "Version", valid_602355
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
  var valid_602356 = header.getOrDefault("X-Amz-Signature")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Signature", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Content-Sha256", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Date")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Date", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Credential")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Credential", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Security-Token")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Security-Token", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Algorithm")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Algorithm", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-SignedHeaders", valid_602362
  result.add "header", section
  ## parameters in `formData` object:
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  var valid_602363 = formData.getOrDefault("RankNames")
  valid_602363 = validateParameter(valid_602363, JArray, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "RankNames", valid_602363
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602364 = formData.getOrDefault("DomainName")
  valid_602364 = validateParameter(valid_602364, JString, required = true,
                                 default = nil)
  if valid_602364 != nil:
    section.add "DomainName", valid_602364
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602365: Call_PostDescribeRankExpressions_602351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_602365.validator(path, query, header, formData, body)
  let scheme = call_602365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602365.url(scheme.get, call_602365.host, call_602365.base,
                         call_602365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602365, url, valid)

proc call*(call_602366: Call_PostDescribeRankExpressions_602351;
          DomainName: string; RankNames: JsonNode = nil;
          Action: string = "DescribeRankExpressions"; Version: string = "2011-02-01"): Recallable =
  ## postDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602367 = newJObject()
  var formData_602368 = newJObject()
  if RankNames != nil:
    formData_602368.add "RankNames", RankNames
  add(formData_602368, "DomainName", newJString(DomainName))
  add(query_602367, "Action", newJString(Action))
  add(query_602367, "Version", newJString(Version))
  result = call_602366.call(nil, query_602367, nil, formData_602368, nil)

var postDescribeRankExpressions* = Call_PostDescribeRankExpressions_602351(
    name: "postDescribeRankExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_PostDescribeRankExpressions_602352, base: "/",
    url: url_PostDescribeRankExpressions_602353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRankExpressions_602334 = ref object of OpenApiRestCall_601389
proc url_GetDescribeRankExpressions_602336(protocol: Scheme; host: string;
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

proc validate_GetDescribeRankExpressions_602335(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602337 = query.getOrDefault("DomainName")
  valid_602337 = validateParameter(valid_602337, JString, required = true,
                                 default = nil)
  if valid_602337 != nil:
    section.add "DomainName", valid_602337
  var valid_602338 = query.getOrDefault("RankNames")
  valid_602338 = validateParameter(valid_602338, JArray, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "RankNames", valid_602338
  var valid_602339 = query.getOrDefault("Action")
  valid_602339 = validateParameter(valid_602339, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_602339 != nil:
    section.add "Action", valid_602339
  var valid_602340 = query.getOrDefault("Version")
  valid_602340 = validateParameter(valid_602340, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602340 != nil:
    section.add "Version", valid_602340
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
  var valid_602341 = header.getOrDefault("X-Amz-Signature")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Signature", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-Content-Sha256", valid_602342
  var valid_602343 = header.getOrDefault("X-Amz-Date")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "X-Amz-Date", valid_602343
  var valid_602344 = header.getOrDefault("X-Amz-Credential")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "X-Amz-Credential", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-Security-Token")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Security-Token", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Algorithm")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Algorithm", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-SignedHeaders", valid_602347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602348: Call_GetDescribeRankExpressions_602334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_602348.validator(path, query, header, formData, body)
  let scheme = call_602348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602348.url(scheme.get, call_602348.host, call_602348.base,
                         call_602348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602348, url, valid)

proc call*(call_602349: Call_GetDescribeRankExpressions_602334; DomainName: string;
          RankNames: JsonNode = nil; Action: string = "DescribeRankExpressions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602350 = newJObject()
  add(query_602350, "DomainName", newJString(DomainName))
  if RankNames != nil:
    query_602350.add "RankNames", RankNames
  add(query_602350, "Action", newJString(Action))
  add(query_602350, "Version", newJString(Version))
  result = call_602349.call(nil, query_602350, nil, nil, nil)

var getDescribeRankExpressions* = Call_GetDescribeRankExpressions_602334(
    name: "getDescribeRankExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_GetDescribeRankExpressions_602335, base: "/",
    url: url_GetDescribeRankExpressions_602336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_602385 = ref object of OpenApiRestCall_601389
proc url_PostDescribeServiceAccessPolicies_602387(protocol: Scheme; host: string;
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

proc validate_PostDescribeServiceAccessPolicies_602386(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
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
  var valid_602388 = query.getOrDefault("Action")
  valid_602388 = validateParameter(valid_602388, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_602388 != nil:
    section.add "Action", valid_602388
  var valid_602389 = query.getOrDefault("Version")
  valid_602389 = validateParameter(valid_602389, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602389 != nil:
    section.add "Version", valid_602389
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
  var valid_602390 = header.getOrDefault("X-Amz-Signature")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-Signature", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Content-Sha256", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-Date")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Date", valid_602392
  var valid_602393 = header.getOrDefault("X-Amz-Credential")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-Credential", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-Security-Token")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Security-Token", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Algorithm")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Algorithm", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-SignedHeaders", valid_602396
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602397 = formData.getOrDefault("DomainName")
  valid_602397 = validateParameter(valid_602397, JString, required = true,
                                 default = nil)
  if valid_602397 != nil:
    section.add "DomainName", valid_602397
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602398: Call_PostDescribeServiceAccessPolicies_602385;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_602398.validator(path, query, header, formData, body)
  let scheme = call_602398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602398.url(scheme.get, call_602398.host, call_602398.base,
                         call_602398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602398, url, valid)

proc call*(call_602399: Call_PostDescribeServiceAccessPolicies_602385;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602400 = newJObject()
  var formData_602401 = newJObject()
  add(formData_602401, "DomainName", newJString(DomainName))
  add(query_602400, "Action", newJString(Action))
  add(query_602400, "Version", newJString(Version))
  result = call_602399.call(nil, query_602400, nil, formData_602401, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_602385(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_602386, base: "/",
    url: url_PostDescribeServiceAccessPolicies_602387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_602369 = ref object of OpenApiRestCall_601389
proc url_GetDescribeServiceAccessPolicies_602371(protocol: Scheme; host: string;
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

proc validate_GetDescribeServiceAccessPolicies_602370(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602372 = query.getOrDefault("DomainName")
  valid_602372 = validateParameter(valid_602372, JString, required = true,
                                 default = nil)
  if valid_602372 != nil:
    section.add "DomainName", valid_602372
  var valid_602373 = query.getOrDefault("Action")
  valid_602373 = validateParameter(valid_602373, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_602373 != nil:
    section.add "Action", valid_602373
  var valid_602374 = query.getOrDefault("Version")
  valid_602374 = validateParameter(valid_602374, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602374 != nil:
    section.add "Version", valid_602374
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
  var valid_602375 = header.getOrDefault("X-Amz-Signature")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Signature", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Content-Sha256", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-Date")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Date", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-Credential")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-Credential", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-Security-Token")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Security-Token", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-Algorithm")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Algorithm", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-SignedHeaders", valid_602381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602382: Call_GetDescribeServiceAccessPolicies_602369;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_602382.validator(path, query, header, formData, body)
  let scheme = call_602382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602382.url(scheme.get, call_602382.host, call_602382.base,
                         call_602382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602382, url, valid)

proc call*(call_602383: Call_GetDescribeServiceAccessPolicies_602369;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602384 = newJObject()
  add(query_602384, "DomainName", newJString(DomainName))
  add(query_602384, "Action", newJString(Action))
  add(query_602384, "Version", newJString(Version))
  result = call_602383.call(nil, query_602384, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_602369(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_602370, base: "/",
    url: url_GetDescribeServiceAccessPolicies_602371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStemmingOptions_602418 = ref object of OpenApiRestCall_601389
proc url_PostDescribeStemmingOptions_602420(protocol: Scheme; host: string;
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

proc validate_PostDescribeStemmingOptions_602419(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stemming dictionary configured for the search domain.
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
  var valid_602421 = query.getOrDefault("Action")
  valid_602421 = validateParameter(valid_602421, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_602421 != nil:
    section.add "Action", valid_602421
  var valid_602422 = query.getOrDefault("Version")
  valid_602422 = validateParameter(valid_602422, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602422 != nil:
    section.add "Version", valid_602422
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
  var valid_602423 = header.getOrDefault("X-Amz-Signature")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-Signature", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Content-Sha256", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Date")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Date", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-Credential")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-Credential", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-Security-Token")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Security-Token", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Algorithm")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Algorithm", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-SignedHeaders", valid_602429
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602430 = formData.getOrDefault("DomainName")
  valid_602430 = validateParameter(valid_602430, JString, required = true,
                                 default = nil)
  if valid_602430 != nil:
    section.add "DomainName", valid_602430
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602431: Call_PostDescribeStemmingOptions_602418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_602431.validator(path, query, header, formData, body)
  let scheme = call_602431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602431.url(scheme.get, call_602431.host, call_602431.base,
                         call_602431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602431, url, valid)

proc call*(call_602432: Call_PostDescribeStemmingOptions_602418;
          DomainName: string; Action: string = "DescribeStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602433 = newJObject()
  var formData_602434 = newJObject()
  add(formData_602434, "DomainName", newJString(DomainName))
  add(query_602433, "Action", newJString(Action))
  add(query_602433, "Version", newJString(Version))
  result = call_602432.call(nil, query_602433, nil, formData_602434, nil)

var postDescribeStemmingOptions* = Call_PostDescribeStemmingOptions_602418(
    name: "postDescribeStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_PostDescribeStemmingOptions_602419, base: "/",
    url: url_PostDescribeStemmingOptions_602420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStemmingOptions_602402 = ref object of OpenApiRestCall_601389
proc url_GetDescribeStemmingOptions_602404(protocol: Scheme; host: string;
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

proc validate_GetDescribeStemmingOptions_602403(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602405 = query.getOrDefault("DomainName")
  valid_602405 = validateParameter(valid_602405, JString, required = true,
                                 default = nil)
  if valid_602405 != nil:
    section.add "DomainName", valid_602405
  var valid_602406 = query.getOrDefault("Action")
  valid_602406 = validateParameter(valid_602406, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_602406 != nil:
    section.add "Action", valid_602406
  var valid_602407 = query.getOrDefault("Version")
  valid_602407 = validateParameter(valid_602407, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602407 != nil:
    section.add "Version", valid_602407
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
  var valid_602408 = header.getOrDefault("X-Amz-Signature")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Signature", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Content-Sha256", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Date")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Date", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Credential")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Credential", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Security-Token")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Security-Token", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Algorithm")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Algorithm", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-SignedHeaders", valid_602414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602415: Call_GetDescribeStemmingOptions_602402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_602415.validator(path, query, header, formData, body)
  let scheme = call_602415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602415.url(scheme.get, call_602415.host, call_602415.base,
                         call_602415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602415, url, valid)

proc call*(call_602416: Call_GetDescribeStemmingOptions_602402; DomainName: string;
          Action: string = "DescribeStemmingOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602417 = newJObject()
  add(query_602417, "DomainName", newJString(DomainName))
  add(query_602417, "Action", newJString(Action))
  add(query_602417, "Version", newJString(Version))
  result = call_602416.call(nil, query_602417, nil, nil, nil)

var getDescribeStemmingOptions* = Call_GetDescribeStemmingOptions_602402(
    name: "getDescribeStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_GetDescribeStemmingOptions_602403, base: "/",
    url: url_GetDescribeStemmingOptions_602404,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStopwordOptions_602451 = ref object of OpenApiRestCall_601389
proc url_PostDescribeStopwordOptions_602453(protocol: Scheme; host: string;
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

proc validate_PostDescribeStopwordOptions_602452(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stopwords configured for the search domain.
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
  var valid_602454 = query.getOrDefault("Action")
  valid_602454 = validateParameter(valid_602454, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_602454 != nil:
    section.add "Action", valid_602454
  var valid_602455 = query.getOrDefault("Version")
  valid_602455 = validateParameter(valid_602455, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602455 != nil:
    section.add "Version", valid_602455
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
  var valid_602456 = header.getOrDefault("X-Amz-Signature")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-Signature", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Content-Sha256", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Date")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Date", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-Credential")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Credential", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Security-Token")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Security-Token", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Algorithm")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Algorithm", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-SignedHeaders", valid_602462
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602463 = formData.getOrDefault("DomainName")
  valid_602463 = validateParameter(valid_602463, JString, required = true,
                                 default = nil)
  if valid_602463 != nil:
    section.add "DomainName", valid_602463
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602464: Call_PostDescribeStopwordOptions_602451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_602464.validator(path, query, header, formData, body)
  let scheme = call_602464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602464.url(scheme.get, call_602464.host, call_602464.base,
                         call_602464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602464, url, valid)

proc call*(call_602465: Call_PostDescribeStopwordOptions_602451;
          DomainName: string; Action: string = "DescribeStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602466 = newJObject()
  var formData_602467 = newJObject()
  add(formData_602467, "DomainName", newJString(DomainName))
  add(query_602466, "Action", newJString(Action))
  add(query_602466, "Version", newJString(Version))
  result = call_602465.call(nil, query_602466, nil, formData_602467, nil)

var postDescribeStopwordOptions* = Call_PostDescribeStopwordOptions_602451(
    name: "postDescribeStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_PostDescribeStopwordOptions_602452, base: "/",
    url: url_PostDescribeStopwordOptions_602453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStopwordOptions_602435 = ref object of OpenApiRestCall_601389
proc url_GetDescribeStopwordOptions_602437(protocol: Scheme; host: string;
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

proc validate_GetDescribeStopwordOptions_602436(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stopwords configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602438 = query.getOrDefault("DomainName")
  valid_602438 = validateParameter(valid_602438, JString, required = true,
                                 default = nil)
  if valid_602438 != nil:
    section.add "DomainName", valid_602438
  var valid_602439 = query.getOrDefault("Action")
  valid_602439 = validateParameter(valid_602439, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_602439 != nil:
    section.add "Action", valid_602439
  var valid_602440 = query.getOrDefault("Version")
  valid_602440 = validateParameter(valid_602440, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602440 != nil:
    section.add "Version", valid_602440
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
  var valid_602441 = header.getOrDefault("X-Amz-Signature")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Signature", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Content-Sha256", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Date")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Date", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Credential")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Credential", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Security-Token")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Security-Token", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Algorithm")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Algorithm", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-SignedHeaders", valid_602447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602448: Call_GetDescribeStopwordOptions_602435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_602448.validator(path, query, header, formData, body)
  let scheme = call_602448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602448.url(scheme.get, call_602448.host, call_602448.base,
                         call_602448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602448, url, valid)

proc call*(call_602449: Call_GetDescribeStopwordOptions_602435; DomainName: string;
          Action: string = "DescribeStopwordOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602450 = newJObject()
  add(query_602450, "DomainName", newJString(DomainName))
  add(query_602450, "Action", newJString(Action))
  add(query_602450, "Version", newJString(Version))
  result = call_602449.call(nil, query_602450, nil, nil, nil)

var getDescribeStopwordOptions* = Call_GetDescribeStopwordOptions_602435(
    name: "getDescribeStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_GetDescribeStopwordOptions_602436, base: "/",
    url: url_GetDescribeStopwordOptions_602437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSynonymOptions_602484 = ref object of OpenApiRestCall_601389
proc url_PostDescribeSynonymOptions_602486(protocol: Scheme; host: string;
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

proc validate_PostDescribeSynonymOptions_602485(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the synonym dictionary configured for the search domain.
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
  var valid_602487 = query.getOrDefault("Action")
  valid_602487 = validateParameter(valid_602487, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_602487 != nil:
    section.add "Action", valid_602487
  var valid_602488 = query.getOrDefault("Version")
  valid_602488 = validateParameter(valid_602488, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602488 != nil:
    section.add "Version", valid_602488
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
  var valid_602489 = header.getOrDefault("X-Amz-Signature")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-Signature", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-Content-Sha256", valid_602490
  var valid_602491 = header.getOrDefault("X-Amz-Date")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Date", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-Credential")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-Credential", valid_602492
  var valid_602493 = header.getOrDefault("X-Amz-Security-Token")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-Security-Token", valid_602493
  var valid_602494 = header.getOrDefault("X-Amz-Algorithm")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Algorithm", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-SignedHeaders", valid_602495
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602496 = formData.getOrDefault("DomainName")
  valid_602496 = validateParameter(valid_602496, JString, required = true,
                                 default = nil)
  if valid_602496 != nil:
    section.add "DomainName", valid_602496
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602497: Call_PostDescribeSynonymOptions_602484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_602497.validator(path, query, header, formData, body)
  let scheme = call_602497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602497.url(scheme.get, call_602497.host, call_602497.base,
                         call_602497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602497, url, valid)

proc call*(call_602498: Call_PostDescribeSynonymOptions_602484; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## postDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602499 = newJObject()
  var formData_602500 = newJObject()
  add(formData_602500, "DomainName", newJString(DomainName))
  add(query_602499, "Action", newJString(Action))
  add(query_602499, "Version", newJString(Version))
  result = call_602498.call(nil, query_602499, nil, formData_602500, nil)

var postDescribeSynonymOptions* = Call_PostDescribeSynonymOptions_602484(
    name: "postDescribeSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_PostDescribeSynonymOptions_602485, base: "/",
    url: url_PostDescribeSynonymOptions_602486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSynonymOptions_602468 = ref object of OpenApiRestCall_601389
proc url_GetDescribeSynonymOptions_602470(protocol: Scheme; host: string;
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

proc validate_GetDescribeSynonymOptions_602469(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602471 = query.getOrDefault("DomainName")
  valid_602471 = validateParameter(valid_602471, JString, required = true,
                                 default = nil)
  if valid_602471 != nil:
    section.add "DomainName", valid_602471
  var valid_602472 = query.getOrDefault("Action")
  valid_602472 = validateParameter(valid_602472, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_602472 != nil:
    section.add "Action", valid_602472
  var valid_602473 = query.getOrDefault("Version")
  valid_602473 = validateParameter(valid_602473, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602473 != nil:
    section.add "Version", valid_602473
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
  var valid_602474 = header.getOrDefault("X-Amz-Signature")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Signature", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Content-Sha256", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Date")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Date", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Credential")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Credential", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-Security-Token")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Security-Token", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Algorithm")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Algorithm", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-SignedHeaders", valid_602480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602481: Call_GetDescribeSynonymOptions_602468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_602481.validator(path, query, header, formData, body)
  let scheme = call_602481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602481.url(scheme.get, call_602481.host, call_602481.base,
                         call_602481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602481, url, valid)

proc call*(call_602482: Call_GetDescribeSynonymOptions_602468; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602483 = newJObject()
  add(query_602483, "DomainName", newJString(DomainName))
  add(query_602483, "Action", newJString(Action))
  add(query_602483, "Version", newJString(Version))
  result = call_602482.call(nil, query_602483, nil, nil, nil)

var getDescribeSynonymOptions* = Call_GetDescribeSynonymOptions_602468(
    name: "getDescribeSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_GetDescribeSynonymOptions_602469, base: "/",
    url: url_GetDescribeSynonymOptions_602470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_602517 = ref object of OpenApiRestCall_601389
proc url_PostIndexDocuments_602519(protocol: Scheme; host: string; base: string;
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

proc validate_PostIndexDocuments_602518(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
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
  var valid_602520 = query.getOrDefault("Action")
  valid_602520 = validateParameter(valid_602520, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_602520 != nil:
    section.add "Action", valid_602520
  var valid_602521 = query.getOrDefault("Version")
  valid_602521 = validateParameter(valid_602521, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602521 != nil:
    section.add "Version", valid_602521
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
  var valid_602522 = header.getOrDefault("X-Amz-Signature")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Signature", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Content-Sha256", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-Date")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Date", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Credential")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Credential", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-Security-Token")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-Security-Token", valid_602526
  var valid_602527 = header.getOrDefault("X-Amz-Algorithm")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "X-Amz-Algorithm", valid_602527
  var valid_602528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602528 = validateParameter(valid_602528, JString, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "X-Amz-SignedHeaders", valid_602528
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602529 = formData.getOrDefault("DomainName")
  valid_602529 = validateParameter(valid_602529, JString, required = true,
                                 default = nil)
  if valid_602529 != nil:
    section.add "DomainName", valid_602529
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602530: Call_PostIndexDocuments_602517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_602530.validator(path, query, header, formData, body)
  let scheme = call_602530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602530.url(scheme.get, call_602530.host, call_602530.base,
                         call_602530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602530, url, valid)

proc call*(call_602531: Call_PostIndexDocuments_602517; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602532 = newJObject()
  var formData_602533 = newJObject()
  add(formData_602533, "DomainName", newJString(DomainName))
  add(query_602532, "Action", newJString(Action))
  add(query_602532, "Version", newJString(Version))
  result = call_602531.call(nil, query_602532, nil, formData_602533, nil)

var postIndexDocuments* = Call_PostIndexDocuments_602517(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_602518, base: "/",
    url: url_PostIndexDocuments_602519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_602501 = ref object of OpenApiRestCall_601389
proc url_GetIndexDocuments_602503(protocol: Scheme; host: string; base: string;
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

proc validate_GetIndexDocuments_602502(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602504 = query.getOrDefault("DomainName")
  valid_602504 = validateParameter(valid_602504, JString, required = true,
                                 default = nil)
  if valid_602504 != nil:
    section.add "DomainName", valid_602504
  var valid_602505 = query.getOrDefault("Action")
  valid_602505 = validateParameter(valid_602505, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_602505 != nil:
    section.add "Action", valid_602505
  var valid_602506 = query.getOrDefault("Version")
  valid_602506 = validateParameter(valid_602506, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602506 != nil:
    section.add "Version", valid_602506
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
  var valid_602507 = header.getOrDefault("X-Amz-Signature")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Signature", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Content-Sha256", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Date")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Date", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Credential")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Credential", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Security-Token")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Security-Token", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-Algorithm")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-Algorithm", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-SignedHeaders", valid_602513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602514: Call_GetIndexDocuments_602501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_602514.validator(path, query, header, formData, body)
  let scheme = call_602514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602514.url(scheme.get, call_602514.host, call_602514.base,
                         call_602514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602514, url, valid)

proc call*(call_602515: Call_GetIndexDocuments_602501; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602516 = newJObject()
  add(query_602516, "DomainName", newJString(DomainName))
  add(query_602516, "Action", newJString(Action))
  add(query_602516, "Version", newJString(Version))
  result = call_602515.call(nil, query_602516, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_602501(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_602502,
    base: "/", url: url_GetIndexDocuments_602503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_602551 = ref object of OpenApiRestCall_601389
proc url_PostUpdateAvailabilityOptions_602553(protocol: Scheme; host: string;
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

proc validate_PostUpdateAvailabilityOptions_602552(path: JsonNode; query: JsonNode;
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
  var valid_602554 = query.getOrDefault("Action")
  valid_602554 = validateParameter(valid_602554, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_602554 != nil:
    section.add "Action", valid_602554
  var valid_602555 = query.getOrDefault("Version")
  valid_602555 = validateParameter(valid_602555, JString, required = true,
                                 default = newJString("2011-02-01"))
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
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MultiAZ` field"
  var valid_602563 = formData.getOrDefault("MultiAZ")
  valid_602563 = validateParameter(valid_602563, JBool, required = true, default = nil)
  if valid_602563 != nil:
    section.add "MultiAZ", valid_602563
  var valid_602564 = formData.getOrDefault("DomainName")
  valid_602564 = validateParameter(valid_602564, JString, required = true,
                                 default = nil)
  if valid_602564 != nil:
    section.add "DomainName", valid_602564
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602565: Call_PostUpdateAvailabilityOptions_602551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602565.validator(path, query, header, formData, body)
  let scheme = call_602565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602565.url(scheme.get, call_602565.host, call_602565.base,
                         call_602565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602565, url, valid)

proc call*(call_602566: Call_PostUpdateAvailabilityOptions_602551; MultiAZ: bool;
          DomainName: string; Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602567 = newJObject()
  var formData_602568 = newJObject()
  add(formData_602568, "MultiAZ", newJBool(MultiAZ))
  add(formData_602568, "DomainName", newJString(DomainName))
  add(query_602567, "Action", newJString(Action))
  add(query_602567, "Version", newJString(Version))
  result = call_602566.call(nil, query_602567, nil, formData_602568, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_602551(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_602552, base: "/",
    url: url_PostUpdateAvailabilityOptions_602553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_602534 = ref object of OpenApiRestCall_601389
proc url_GetUpdateAvailabilityOptions_602536(protocol: Scheme; host: string;
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

proc validate_GetUpdateAvailabilityOptions_602535(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602537 = query.getOrDefault("DomainName")
  valid_602537 = validateParameter(valid_602537, JString, required = true,
                                 default = nil)
  if valid_602537 != nil:
    section.add "DomainName", valid_602537
  var valid_602538 = query.getOrDefault("Action")
  valid_602538 = validateParameter(valid_602538, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_602538 != nil:
    section.add "Action", valid_602538
  var valid_602539 = query.getOrDefault("MultiAZ")
  valid_602539 = validateParameter(valid_602539, JBool, required = true, default = nil)
  if valid_602539 != nil:
    section.add "MultiAZ", valid_602539
  var valid_602540 = query.getOrDefault("Version")
  valid_602540 = validateParameter(valid_602540, JString, required = true,
                                 default = newJString("2011-02-01"))
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

proc call*(call_602548: Call_GetUpdateAvailabilityOptions_602534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_602548.validator(path, query, header, formData, body)
  let scheme = call_602548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602548.url(scheme.get, call_602548.host, call_602548.base,
                         call_602548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602548, url, valid)

proc call*(call_602549: Call_GetUpdateAvailabilityOptions_602534;
          DomainName: string; MultiAZ: bool;
          Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Version: string (required)
  var query_602550 = newJObject()
  add(query_602550, "DomainName", newJString(DomainName))
  add(query_602550, "Action", newJString(Action))
  add(query_602550, "MultiAZ", newJBool(MultiAZ))
  add(query_602550, "Version", newJString(Version))
  result = call_602549.call(nil, query_602550, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_602534(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_602535, base: "/",
    url: url_GetUpdateAvailabilityOptions_602536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDefaultSearchField_602586 = ref object of OpenApiRestCall_601389
proc url_PostUpdateDefaultSearchField_602588(protocol: Scheme; host: string;
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

proc validate_PostUpdateDefaultSearchField_602587(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
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
  var valid_602589 = query.getOrDefault("Action")
  valid_602589 = validateParameter(valid_602589, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_602589 != nil:
    section.add "Action", valid_602589
  var valid_602590 = query.getOrDefault("Version")
  valid_602590 = validateParameter(valid_602590, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602590 != nil:
    section.add "Version", valid_602590
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
  var valid_602591 = header.getOrDefault("X-Amz-Signature")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-Signature", valid_602591
  var valid_602592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602592 = validateParameter(valid_602592, JString, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "X-Amz-Content-Sha256", valid_602592
  var valid_602593 = header.getOrDefault("X-Amz-Date")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-Date", valid_602593
  var valid_602594 = header.getOrDefault("X-Amz-Credential")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "X-Amz-Credential", valid_602594
  var valid_602595 = header.getOrDefault("X-Amz-Security-Token")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Security-Token", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-Algorithm")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Algorithm", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-SignedHeaders", valid_602597
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602598 = formData.getOrDefault("DomainName")
  valid_602598 = validateParameter(valid_602598, JString, required = true,
                                 default = nil)
  if valid_602598 != nil:
    section.add "DomainName", valid_602598
  var valid_602599 = formData.getOrDefault("DefaultSearchField")
  valid_602599 = validateParameter(valid_602599, JString, required = true,
                                 default = nil)
  if valid_602599 != nil:
    section.add "DefaultSearchField", valid_602599
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602600: Call_PostUpdateDefaultSearchField_602586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_602600.validator(path, query, header, formData, body)
  let scheme = call_602600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602600.url(scheme.get, call_602600.host, call_602600.base,
                         call_602600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602600, url, valid)

proc call*(call_602601: Call_PostUpdateDefaultSearchField_602586;
          DomainName: string; DefaultSearchField: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Version: string (required)
  var query_602602 = newJObject()
  var formData_602603 = newJObject()
  add(formData_602603, "DomainName", newJString(DomainName))
  add(query_602602, "Action", newJString(Action))
  add(formData_602603, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_602602, "Version", newJString(Version))
  result = call_602601.call(nil, query_602602, nil, formData_602603, nil)

var postUpdateDefaultSearchField* = Call_PostUpdateDefaultSearchField_602586(
    name: "postUpdateDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_PostUpdateDefaultSearchField_602587, base: "/",
    url: url_PostUpdateDefaultSearchField_602588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDefaultSearchField_602569 = ref object of OpenApiRestCall_601389
proc url_GetUpdateDefaultSearchField_602571(protocol: Scheme; host: string;
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

proc validate_GetUpdateDefaultSearchField_602570(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602572 = query.getOrDefault("DomainName")
  valid_602572 = validateParameter(valid_602572, JString, required = true,
                                 default = nil)
  if valid_602572 != nil:
    section.add "DomainName", valid_602572
  var valid_602573 = query.getOrDefault("DefaultSearchField")
  valid_602573 = validateParameter(valid_602573, JString, required = true,
                                 default = nil)
  if valid_602573 != nil:
    section.add "DefaultSearchField", valid_602573
  var valid_602574 = query.getOrDefault("Action")
  valid_602574 = validateParameter(valid_602574, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_602574 != nil:
    section.add "Action", valid_602574
  var valid_602575 = query.getOrDefault("Version")
  valid_602575 = validateParameter(valid_602575, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602575 != nil:
    section.add "Version", valid_602575
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
  var valid_602576 = header.getOrDefault("X-Amz-Signature")
  valid_602576 = validateParameter(valid_602576, JString, required = false,
                                 default = nil)
  if valid_602576 != nil:
    section.add "X-Amz-Signature", valid_602576
  var valid_602577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-Content-Sha256", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-Date")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Date", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-Credential")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Credential", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Security-Token")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Security-Token", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-Algorithm")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Algorithm", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-SignedHeaders", valid_602582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602583: Call_GetUpdateDefaultSearchField_602569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_602583.validator(path, query, header, formData, body)
  let scheme = call_602583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602583.url(scheme.get, call_602583.host, call_602583.base,
                         call_602583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602583, url, valid)

proc call*(call_602584: Call_GetUpdateDefaultSearchField_602569;
          DomainName: string; DefaultSearchField: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602585 = newJObject()
  add(query_602585, "DomainName", newJString(DomainName))
  add(query_602585, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_602585, "Action", newJString(Action))
  add(query_602585, "Version", newJString(Version))
  result = call_602584.call(nil, query_602585, nil, nil, nil)

var getUpdateDefaultSearchField* = Call_GetUpdateDefaultSearchField_602569(
    name: "getUpdateDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_GetUpdateDefaultSearchField_602570, base: "/",
    url: url_GetUpdateDefaultSearchField_602571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_602621 = ref object of OpenApiRestCall_601389
proc url_PostUpdateServiceAccessPolicies_602623(protocol: Scheme; host: string;
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

proc validate_PostUpdateServiceAccessPolicies_602622(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
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
  var valid_602624 = query.getOrDefault("Action")
  valid_602624 = validateParameter(valid_602624, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_602624 != nil:
    section.add "Action", valid_602624
  var valid_602625 = query.getOrDefault("Version")
  valid_602625 = validateParameter(valid_602625, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602625 != nil:
    section.add "Version", valid_602625
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
  var valid_602626 = header.getOrDefault("X-Amz-Signature")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-Signature", valid_602626
  var valid_602627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Content-Sha256", valid_602627
  var valid_602628 = header.getOrDefault("X-Amz-Date")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Date", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-Credential")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-Credential", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-Security-Token")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Security-Token", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-Algorithm")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-Algorithm", valid_602631
  var valid_602632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "X-Amz-SignedHeaders", valid_602632
  result.add "header", section
  ## parameters in `formData` object:
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AccessPolicies` field"
  var valid_602633 = formData.getOrDefault("AccessPolicies")
  valid_602633 = validateParameter(valid_602633, JString, required = true,
                                 default = nil)
  if valid_602633 != nil:
    section.add "AccessPolicies", valid_602633
  var valid_602634 = formData.getOrDefault("DomainName")
  valid_602634 = validateParameter(valid_602634, JString, required = true,
                                 default = nil)
  if valid_602634 != nil:
    section.add "DomainName", valid_602634
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602635: Call_PostUpdateServiceAccessPolicies_602621;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_602635.validator(path, query, header, formData, body)
  let scheme = call_602635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602635.url(scheme.get, call_602635.host, call_602635.base,
                         call_602635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602635, url, valid)

proc call*(call_602636: Call_PostUpdateServiceAccessPolicies_602621;
          AccessPolicies: string; DomainName: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602637 = newJObject()
  var formData_602638 = newJObject()
  add(formData_602638, "AccessPolicies", newJString(AccessPolicies))
  add(formData_602638, "DomainName", newJString(DomainName))
  add(query_602637, "Action", newJString(Action))
  add(query_602637, "Version", newJString(Version))
  result = call_602636.call(nil, query_602637, nil, formData_602638, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_602621(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_602622, base: "/",
    url: url_PostUpdateServiceAccessPolicies_602623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_602604 = ref object of OpenApiRestCall_601389
proc url_GetUpdateServiceAccessPolicies_602606(protocol: Scheme; host: string;
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

proc validate_GetUpdateServiceAccessPolicies_602605(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_602607 = query.getOrDefault("DomainName")
  valid_602607 = validateParameter(valid_602607, JString, required = true,
                                 default = nil)
  if valid_602607 != nil:
    section.add "DomainName", valid_602607
  var valid_602608 = query.getOrDefault("Action")
  valid_602608 = validateParameter(valid_602608, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_602608 != nil:
    section.add "Action", valid_602608
  var valid_602609 = query.getOrDefault("Version")
  valid_602609 = validateParameter(valid_602609, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602609 != nil:
    section.add "Version", valid_602609
  var valid_602610 = query.getOrDefault("AccessPolicies")
  valid_602610 = validateParameter(valid_602610, JString, required = true,
                                 default = nil)
  if valid_602610 != nil:
    section.add "AccessPolicies", valid_602610
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
  var valid_602611 = header.getOrDefault("X-Amz-Signature")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Signature", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Content-Sha256", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-Date")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Date", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-Credential")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-Credential", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-Security-Token")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-Security-Token", valid_602615
  var valid_602616 = header.getOrDefault("X-Amz-Algorithm")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "X-Amz-Algorithm", valid_602616
  var valid_602617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602617 = validateParameter(valid_602617, JString, required = false,
                                 default = nil)
  if valid_602617 != nil:
    section.add "X-Amz-SignedHeaders", valid_602617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602618: Call_GetUpdateServiceAccessPolicies_602604; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_602618.validator(path, query, header, formData, body)
  let scheme = call_602618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602618.url(scheme.get, call_602618.host, call_602618.base,
                         call_602618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602618, url, valid)

proc call*(call_602619: Call_GetUpdateServiceAccessPolicies_602604;
          DomainName: string; AccessPolicies: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  var query_602620 = newJObject()
  add(query_602620, "DomainName", newJString(DomainName))
  add(query_602620, "Action", newJString(Action))
  add(query_602620, "Version", newJString(Version))
  add(query_602620, "AccessPolicies", newJString(AccessPolicies))
  result = call_602619.call(nil, query_602620, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_602604(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_602605, base: "/",
    url: url_GetUpdateServiceAccessPolicies_602606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStemmingOptions_602656 = ref object of OpenApiRestCall_601389
proc url_PostUpdateStemmingOptions_602658(protocol: Scheme; host: string;
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

proc validate_PostUpdateStemmingOptions_602657(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
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
  var valid_602659 = query.getOrDefault("Action")
  valid_602659 = validateParameter(valid_602659, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_602659 != nil:
    section.add "Action", valid_602659
  var valid_602660 = query.getOrDefault("Version")
  valid_602660 = validateParameter(valid_602660, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602660 != nil:
    section.add "Version", valid_602660
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
  var valid_602661 = header.getOrDefault("X-Amz-Signature")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-Signature", valid_602661
  var valid_602662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-Content-Sha256", valid_602662
  var valid_602663 = header.getOrDefault("X-Amz-Date")
  valid_602663 = validateParameter(valid_602663, JString, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "X-Amz-Date", valid_602663
  var valid_602664 = header.getOrDefault("X-Amz-Credential")
  valid_602664 = validateParameter(valid_602664, JString, required = false,
                                 default = nil)
  if valid_602664 != nil:
    section.add "X-Amz-Credential", valid_602664
  var valid_602665 = header.getOrDefault("X-Amz-Security-Token")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "X-Amz-Security-Token", valid_602665
  var valid_602666 = header.getOrDefault("X-Amz-Algorithm")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "X-Amz-Algorithm", valid_602666
  var valid_602667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602667 = validateParameter(valid_602667, JString, required = false,
                                 default = nil)
  if valid_602667 != nil:
    section.add "X-Amz-SignedHeaders", valid_602667
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602668 = formData.getOrDefault("DomainName")
  valid_602668 = validateParameter(valid_602668, JString, required = true,
                                 default = nil)
  if valid_602668 != nil:
    section.add "DomainName", valid_602668
  var valid_602669 = formData.getOrDefault("Stems")
  valid_602669 = validateParameter(valid_602669, JString, required = true,
                                 default = nil)
  if valid_602669 != nil:
    section.add "Stems", valid_602669
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602670: Call_PostUpdateStemmingOptions_602656; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_602670.validator(path, query, header, formData, body)
  let scheme = call_602670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602670.url(scheme.get, call_602670.host, call_602670.base,
                         call_602670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602670, url, valid)

proc call*(call_602671: Call_PostUpdateStemmingOptions_602656; DomainName: string;
          Stems: string; Action: string = "UpdateStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateStemmingOptions
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Stems: string (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   Version: string (required)
  var query_602672 = newJObject()
  var formData_602673 = newJObject()
  add(formData_602673, "DomainName", newJString(DomainName))
  add(query_602672, "Action", newJString(Action))
  add(formData_602673, "Stems", newJString(Stems))
  add(query_602672, "Version", newJString(Version))
  result = call_602671.call(nil, query_602672, nil, formData_602673, nil)

var postUpdateStemmingOptions* = Call_PostUpdateStemmingOptions_602656(
    name: "postUpdateStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_PostUpdateStemmingOptions_602657, base: "/",
    url: url_PostUpdateStemmingOptions_602658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStemmingOptions_602639 = ref object of OpenApiRestCall_601389
proc url_GetUpdateStemmingOptions_602641(protocol: Scheme; host: string;
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

proc validate_GetUpdateStemmingOptions_602640(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Stems` field"
  var valid_602642 = query.getOrDefault("Stems")
  valid_602642 = validateParameter(valid_602642, JString, required = true,
                                 default = nil)
  if valid_602642 != nil:
    section.add "Stems", valid_602642
  var valid_602643 = query.getOrDefault("DomainName")
  valid_602643 = validateParameter(valid_602643, JString, required = true,
                                 default = nil)
  if valid_602643 != nil:
    section.add "DomainName", valid_602643
  var valid_602644 = query.getOrDefault("Action")
  valid_602644 = validateParameter(valid_602644, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_602644 != nil:
    section.add "Action", valid_602644
  var valid_602645 = query.getOrDefault("Version")
  valid_602645 = validateParameter(valid_602645, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602645 != nil:
    section.add "Version", valid_602645
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
  var valid_602646 = header.getOrDefault("X-Amz-Signature")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-Signature", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-Content-Sha256", valid_602647
  var valid_602648 = header.getOrDefault("X-Amz-Date")
  valid_602648 = validateParameter(valid_602648, JString, required = false,
                                 default = nil)
  if valid_602648 != nil:
    section.add "X-Amz-Date", valid_602648
  var valid_602649 = header.getOrDefault("X-Amz-Credential")
  valid_602649 = validateParameter(valid_602649, JString, required = false,
                                 default = nil)
  if valid_602649 != nil:
    section.add "X-Amz-Credential", valid_602649
  var valid_602650 = header.getOrDefault("X-Amz-Security-Token")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "X-Amz-Security-Token", valid_602650
  var valid_602651 = header.getOrDefault("X-Amz-Algorithm")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "X-Amz-Algorithm", valid_602651
  var valid_602652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "X-Amz-SignedHeaders", valid_602652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602653: Call_GetUpdateStemmingOptions_602639; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_602653.validator(path, query, header, formData, body)
  let scheme = call_602653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602653.url(scheme.get, call_602653.host, call_602653.base,
                         call_602653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602653, url, valid)

proc call*(call_602654: Call_GetUpdateStemmingOptions_602639; Stems: string;
          DomainName: string; Action: string = "UpdateStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStemmingOptions
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ##   Stems: string (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602655 = newJObject()
  add(query_602655, "Stems", newJString(Stems))
  add(query_602655, "DomainName", newJString(DomainName))
  add(query_602655, "Action", newJString(Action))
  add(query_602655, "Version", newJString(Version))
  result = call_602654.call(nil, query_602655, nil, nil, nil)

var getUpdateStemmingOptions* = Call_GetUpdateStemmingOptions_602639(
    name: "getUpdateStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_GetUpdateStemmingOptions_602640, base: "/",
    url: url_GetUpdateStemmingOptions_602641, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStopwordOptions_602691 = ref object of OpenApiRestCall_601389
proc url_PostUpdateStopwordOptions_602693(protocol: Scheme; host: string;
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

proc validate_PostUpdateStopwordOptions_602692(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
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
  var valid_602694 = query.getOrDefault("Action")
  valid_602694 = validateParameter(valid_602694, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_602694 != nil:
    section.add "Action", valid_602694
  var valid_602695 = query.getOrDefault("Version")
  valid_602695 = validateParameter(valid_602695, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602695 != nil:
    section.add "Version", valid_602695
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
  var valid_602696 = header.getOrDefault("X-Amz-Signature")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-Signature", valid_602696
  var valid_602697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "X-Amz-Content-Sha256", valid_602697
  var valid_602698 = header.getOrDefault("X-Amz-Date")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Date", valid_602698
  var valid_602699 = header.getOrDefault("X-Amz-Credential")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "X-Amz-Credential", valid_602699
  var valid_602700 = header.getOrDefault("X-Amz-Security-Token")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-Security-Token", valid_602700
  var valid_602701 = header.getOrDefault("X-Amz-Algorithm")
  valid_602701 = validateParameter(valid_602701, JString, required = false,
                                 default = nil)
  if valid_602701 != nil:
    section.add "X-Amz-Algorithm", valid_602701
  var valid_602702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "X-Amz-SignedHeaders", valid_602702
  result.add "header", section
  ## parameters in `formData` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Stopwords` field"
  var valid_602703 = formData.getOrDefault("Stopwords")
  valid_602703 = validateParameter(valid_602703, JString, required = true,
                                 default = nil)
  if valid_602703 != nil:
    section.add "Stopwords", valid_602703
  var valid_602704 = formData.getOrDefault("DomainName")
  valid_602704 = validateParameter(valid_602704, JString, required = true,
                                 default = nil)
  if valid_602704 != nil:
    section.add "DomainName", valid_602704
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602705: Call_PostUpdateStopwordOptions_602691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_602705.validator(path, query, header, formData, body)
  let scheme = call_602705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602705.url(scheme.get, call_602705.host, call_602705.base,
                         call_602705.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602705, url, valid)

proc call*(call_602706: Call_PostUpdateStopwordOptions_602691; Stopwords: string;
          DomainName: string; Action: string = "UpdateStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602707 = newJObject()
  var formData_602708 = newJObject()
  add(formData_602708, "Stopwords", newJString(Stopwords))
  add(formData_602708, "DomainName", newJString(DomainName))
  add(query_602707, "Action", newJString(Action))
  add(query_602707, "Version", newJString(Version))
  result = call_602706.call(nil, query_602707, nil, formData_602708, nil)

var postUpdateStopwordOptions* = Call_PostUpdateStopwordOptions_602691(
    name: "postUpdateStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_PostUpdateStopwordOptions_602692, base: "/",
    url: url_PostUpdateStopwordOptions_602693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStopwordOptions_602674 = ref object of OpenApiRestCall_601389
proc url_GetUpdateStopwordOptions_602676(protocol: Scheme; host: string;
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

proc validate_GetUpdateStopwordOptions_602675(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Stopwords` field"
  var valid_602677 = query.getOrDefault("Stopwords")
  valid_602677 = validateParameter(valid_602677, JString, required = true,
                                 default = nil)
  if valid_602677 != nil:
    section.add "Stopwords", valid_602677
  var valid_602678 = query.getOrDefault("DomainName")
  valid_602678 = validateParameter(valid_602678, JString, required = true,
                                 default = nil)
  if valid_602678 != nil:
    section.add "DomainName", valid_602678
  var valid_602679 = query.getOrDefault("Action")
  valid_602679 = validateParameter(valid_602679, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_602679 != nil:
    section.add "Action", valid_602679
  var valid_602680 = query.getOrDefault("Version")
  valid_602680 = validateParameter(valid_602680, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602680 != nil:
    section.add "Version", valid_602680
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
  var valid_602681 = header.getOrDefault("X-Amz-Signature")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-Signature", valid_602681
  var valid_602682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602682 = validateParameter(valid_602682, JString, required = false,
                                 default = nil)
  if valid_602682 != nil:
    section.add "X-Amz-Content-Sha256", valid_602682
  var valid_602683 = header.getOrDefault("X-Amz-Date")
  valid_602683 = validateParameter(valid_602683, JString, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "X-Amz-Date", valid_602683
  var valid_602684 = header.getOrDefault("X-Amz-Credential")
  valid_602684 = validateParameter(valid_602684, JString, required = false,
                                 default = nil)
  if valid_602684 != nil:
    section.add "X-Amz-Credential", valid_602684
  var valid_602685 = header.getOrDefault("X-Amz-Security-Token")
  valid_602685 = validateParameter(valid_602685, JString, required = false,
                                 default = nil)
  if valid_602685 != nil:
    section.add "X-Amz-Security-Token", valid_602685
  var valid_602686 = header.getOrDefault("X-Amz-Algorithm")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "X-Amz-Algorithm", valid_602686
  var valid_602687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-SignedHeaders", valid_602687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602688: Call_GetUpdateStopwordOptions_602674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_602688.validator(path, query, header, formData, body)
  let scheme = call_602688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602688.url(scheme.get, call_602688.host, call_602688.base,
                         call_602688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602688, url, valid)

proc call*(call_602689: Call_GetUpdateStopwordOptions_602674; Stopwords: string;
          DomainName: string; Action: string = "UpdateStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602690 = newJObject()
  add(query_602690, "Stopwords", newJString(Stopwords))
  add(query_602690, "DomainName", newJString(DomainName))
  add(query_602690, "Action", newJString(Action))
  add(query_602690, "Version", newJString(Version))
  result = call_602689.call(nil, query_602690, nil, nil, nil)

var getUpdateStopwordOptions* = Call_GetUpdateStopwordOptions_602674(
    name: "getUpdateStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_GetUpdateStopwordOptions_602675, base: "/",
    url: url_GetUpdateStopwordOptions_602676, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateSynonymOptions_602726 = ref object of OpenApiRestCall_601389
proc url_PostUpdateSynonymOptions_602728(protocol: Scheme; host: string;
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

proc validate_PostUpdateSynonymOptions_602727(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
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
  var valid_602729 = query.getOrDefault("Action")
  valid_602729 = validateParameter(valid_602729, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_602729 != nil:
    section.add "Action", valid_602729
  var valid_602730 = query.getOrDefault("Version")
  valid_602730 = validateParameter(valid_602730, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602730 != nil:
    section.add "Version", valid_602730
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
  var valid_602731 = header.getOrDefault("X-Amz-Signature")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "X-Amz-Signature", valid_602731
  var valid_602732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602732 = validateParameter(valid_602732, JString, required = false,
                                 default = nil)
  if valid_602732 != nil:
    section.add "X-Amz-Content-Sha256", valid_602732
  var valid_602733 = header.getOrDefault("X-Amz-Date")
  valid_602733 = validateParameter(valid_602733, JString, required = false,
                                 default = nil)
  if valid_602733 != nil:
    section.add "X-Amz-Date", valid_602733
  var valid_602734 = header.getOrDefault("X-Amz-Credential")
  valid_602734 = validateParameter(valid_602734, JString, required = false,
                                 default = nil)
  if valid_602734 != nil:
    section.add "X-Amz-Credential", valid_602734
  var valid_602735 = header.getOrDefault("X-Amz-Security-Token")
  valid_602735 = validateParameter(valid_602735, JString, required = false,
                                 default = nil)
  if valid_602735 != nil:
    section.add "X-Amz-Security-Token", valid_602735
  var valid_602736 = header.getOrDefault("X-Amz-Algorithm")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "X-Amz-Algorithm", valid_602736
  var valid_602737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602737 = validateParameter(valid_602737, JString, required = false,
                                 default = nil)
  if valid_602737 != nil:
    section.add "X-Amz-SignedHeaders", valid_602737
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_602738 = formData.getOrDefault("DomainName")
  valid_602738 = validateParameter(valid_602738, JString, required = true,
                                 default = nil)
  if valid_602738 != nil:
    section.add "DomainName", valid_602738
  var valid_602739 = formData.getOrDefault("Synonyms")
  valid_602739 = validateParameter(valid_602739, JString, required = true,
                                 default = nil)
  if valid_602739 != nil:
    section.add "Synonyms", valid_602739
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602740: Call_PostUpdateSynonymOptions_602726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_602740.validator(path, query, header, formData, body)
  let scheme = call_602740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602740.url(scheme.get, call_602740.host, call_602740.base,
                         call_602740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602740, url, valid)

proc call*(call_602741: Call_PostUpdateSynonymOptions_602726; DomainName: string;
          Synonyms: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   Version: string (required)
  var query_602742 = newJObject()
  var formData_602743 = newJObject()
  add(formData_602743, "DomainName", newJString(DomainName))
  add(query_602742, "Action", newJString(Action))
  add(formData_602743, "Synonyms", newJString(Synonyms))
  add(query_602742, "Version", newJString(Version))
  result = call_602741.call(nil, query_602742, nil, formData_602743, nil)

var postUpdateSynonymOptions* = Call_PostUpdateSynonymOptions_602726(
    name: "postUpdateSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_PostUpdateSynonymOptions_602727, base: "/",
    url: url_PostUpdateSynonymOptions_602728, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateSynonymOptions_602709 = ref object of OpenApiRestCall_601389
proc url_GetUpdateSynonymOptions_602711(protocol: Scheme; host: string; base: string;
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

proc validate_GetUpdateSynonymOptions_602710(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Synonyms` field"
  var valid_602712 = query.getOrDefault("Synonyms")
  valid_602712 = validateParameter(valid_602712, JString, required = true,
                                 default = nil)
  if valid_602712 != nil:
    section.add "Synonyms", valid_602712
  var valid_602713 = query.getOrDefault("DomainName")
  valid_602713 = validateParameter(valid_602713, JString, required = true,
                                 default = nil)
  if valid_602713 != nil:
    section.add "DomainName", valid_602713
  var valid_602714 = query.getOrDefault("Action")
  valid_602714 = validateParameter(valid_602714, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_602714 != nil:
    section.add "Action", valid_602714
  var valid_602715 = query.getOrDefault("Version")
  valid_602715 = validateParameter(valid_602715, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602715 != nil:
    section.add "Version", valid_602715
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
  var valid_602716 = header.getOrDefault("X-Amz-Signature")
  valid_602716 = validateParameter(valid_602716, JString, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "X-Amz-Signature", valid_602716
  var valid_602717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602717 = validateParameter(valid_602717, JString, required = false,
                                 default = nil)
  if valid_602717 != nil:
    section.add "X-Amz-Content-Sha256", valid_602717
  var valid_602718 = header.getOrDefault("X-Amz-Date")
  valid_602718 = validateParameter(valid_602718, JString, required = false,
                                 default = nil)
  if valid_602718 != nil:
    section.add "X-Amz-Date", valid_602718
  var valid_602719 = header.getOrDefault("X-Amz-Credential")
  valid_602719 = validateParameter(valid_602719, JString, required = false,
                                 default = nil)
  if valid_602719 != nil:
    section.add "X-Amz-Credential", valid_602719
  var valid_602720 = header.getOrDefault("X-Amz-Security-Token")
  valid_602720 = validateParameter(valid_602720, JString, required = false,
                                 default = nil)
  if valid_602720 != nil:
    section.add "X-Amz-Security-Token", valid_602720
  var valid_602721 = header.getOrDefault("X-Amz-Algorithm")
  valid_602721 = validateParameter(valid_602721, JString, required = false,
                                 default = nil)
  if valid_602721 != nil:
    section.add "X-Amz-Algorithm", valid_602721
  var valid_602722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602722 = validateParameter(valid_602722, JString, required = false,
                                 default = nil)
  if valid_602722 != nil:
    section.add "X-Amz-SignedHeaders", valid_602722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602723: Call_GetUpdateSynonymOptions_602709; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_602723.validator(path, query, header, formData, body)
  let scheme = call_602723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602723.url(scheme.get, call_602723.host, call_602723.base,
                         call_602723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602723, url, valid)

proc call*(call_602724: Call_GetUpdateSynonymOptions_602709; Synonyms: string;
          DomainName: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602725 = newJObject()
  add(query_602725, "Synonyms", newJString(Synonyms))
  add(query_602725, "DomainName", newJString(DomainName))
  add(query_602725, "Action", newJString(Action))
  add(query_602725, "Version", newJString(Version))
  result = call_602724.call(nil, query_602725, nil, nil, nil)

var getUpdateSynonymOptions* = Call_GetUpdateSynonymOptions_602709(
    name: "getUpdateSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_GetUpdateSynonymOptions_602710, base: "/",
    url: url_GetUpdateSynonymOptions_602711, schemes: {Scheme.Https, Scheme.Http})
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
